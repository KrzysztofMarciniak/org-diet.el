;;; org-diet.el --- Daily diet logging for Org Capture -*- lexical-binding: t -*-

;; Author: Krzysztof Marciniak
;; Version: 0.3
;; Keywords: org, convenience, diet
;; URL: https://github.com/KrzysztofMarciniak/org-diet.el
;; Package-Requires: ((emacs "25.1") (org "9.0"))

;;; Commentary:

;; Org Capture template that logs meals into ~/org/diet/YYYY-MM-DD.org.
;; Uses (file+function FILE-FUNC POS-FUNC) so Org opens the file and then
;; runs POS-FUNC *inside that buffer*.
;;; Code:

(defgroup org-diet nil
  "Daily diet logging for Org Capture."
  :group 'org
  :prefix "org-diet-")

;; --- Path Helpers ------------------------------------------------------------
(defun org-diet-daily-file ()
  "Return the full path of today's diet file as a string."
  (expand-file-name
   (concat (format-time-string "%Y-%m-%d") ".org")
   "~/org/diet/"))

(defun org-diet-ensure-dir ()
  "Ensure the diet directory exists."
  (let ((dir (expand-file-name "~/org/diet/")))
    (unless (file-directory-p dir)
      (make-directory dir t))))

;; --- Table Helpers -----------------------------------------------------------
(defun org-diet-ensure-table-in-buffer ()
  "Ensure the diet table exists somewhere in current buffer; append if missing."
  (save-excursion
    (goto-char (point-min))
    (unless (re-search-forward org-table-line-regexp nil t)
      (goto-char (point-max))
      (insert "\n| Time   | Food | Calories |\n")
      (insert "|--------|------|----------|\n")
      (insert "|        |      |          |\n\n"))))

(defun org-diet-move-point-to-first-data-row ()
  "Move point to the first data row of the diet table."
  (goto-char (point-min))
  (re-search-forward org-table-line-regexp nil t)
  (re-search-forward org-table-hline-regexp nil t)
  (forward-line 1)
  (point))

;; --- Capture-position function ----------------------------------------------
(defun org-diet-position-for-capture ()
  "Position point in today's diet buffer for Org Capture insertion."
  (unless (derived-mode-p 'org-mode)
    (org-mode))
  (when (zerop (buffer-size))
    (org-diet-ensure-table-in-buffer)
    (save-buffer))
  (org-diet-ensure-table-in-buffer)
  (org-diet-move-point-to-first-data-row)
  nil)

;; --- Total Calories ----------------------------------------------------------
(defun org-diet-update-total-calories-in-buffer ()
  "Recalculate total calories from the diet table in the current buffer."
  (let ((total 0))
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^|\\s-*Time\\b" nil t)
        (forward-line 2)
        (while (and (not (eobp)) (looking-at "^|"))
          (let* ((line (buffer-substring-no-properties
                        (line-beginning-position)
                        (line-end-position)))
                 (cols (mapcar #'string-trim (split-string line "|" t)))
                 (cal  (nth 2 cols)))
            (when (and cal (string-match-p "^[0-9]+$" cal))
              (setq total (+ total (string-to-number cal)))))
          (forward-line 1))))
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward "^#\\+TOTAL-CALORIES:.*$" nil t)
          (replace-match (format "#+TOTAL-CALORIES: %d" total) t t)
        (goto-char (point-min))
        (insert (format "#+TOTAL-CALORIES: %d\n" total))))))

;; --- Capture finalize hook ---------------------------------------------------
(defun org-diet-after-capture-finalize (&rest _args)
  "Update total calories after Org Capture finalizes."
  (let ((file (org-diet-daily-file)))
    (when (file-exists-p file)
      (with-current-buffer (find-file-noselect file)
        (org-diet-update-total-calories-in-buffer)
        (save-buffer)))))

(unless (member #'org-diet-after-capture-finalize org-capture-after-finalize-hook)
  (add-hook 'org-capture-after-finalize-hook #'org-diet-after-capture-finalize))

;; --- Capture template --------------------------------------------------------
(defun org-diet-register-capture ()
  "Register the diet Org Capture template."
  (add-to-list 'org-capture-templates
               `("d" "Diet log" table-line
                 (file+function org-diet-daily-file org-diet-position-for-capture)
                 "| %<%H:%M> | %^{Food} | %^{Calories} |"
                 :prepend t
                 :unnarrowed t
                 :jump-to-captured t)))

(with-eval-after-load 'org-capture
  (org-diet-register-capture))

(provide 'org-diet)
;;; org-diet.el ends here
