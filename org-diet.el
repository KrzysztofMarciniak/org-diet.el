;;; org-diet.el --- Daily diet logging for Org Capture -*- lexical-binding: t -*-

;; Author: Krzysztof Marciniak
;; Version: 0.3
;; Keywords: org, convenience, diet
;; URL: https://github.com/KrzysztofMarciniak/org-diet.el
;; Package-Requires: ((emacs "25.1") (org "9.0"))

;;; Commentary:

;; Org Capture template that logs meals into ~/org/diet/YYYY-MM-DD.org.
;; Uses (file+function FILE-FUNC POS-FUNC) so Org opens the file and then
;; runs POS-FUNC *inside that buffer*. This guarantees insertion goes into
;; the correct file, not the currently selected buffer.

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
  "Move `point` to the first data row of the diet table in current buffer.
Return the current point."
  (goto-char (point-min))
  (re-search-forward org-table-line-regexp nil t)
  (re-search-forward org-table-hline-regexp nil t)
  (forward-line 1)
  (point))

;; --- Capture-position function for file+function -----------------------------
(defun org-diet-position-for-capture ()
  "Position point in today's diet buffer for Org Capture insertion.
This function is intended to be called *inside* the target buffer by Org."
  ;; Ensure we're in org-mode
  (unless (derived-mode-p 'org-mode)
    (org-mode))
  ;; Initialize table if buffer empty or missing table
  (when (zerop (buffer-size))
    (org-diet-ensure-table-in-buffer)
    (save-buffer))
  (org-diet-ensure-table-in-buffer)
  (save-buffer)
  ;; Move point to first data row and leave point there
  (org-diet-move-point-to-first-data-row)
  nil)

;; --- Capture template registration (file+function) --------------------------
(defun org-diet-register-capture ()
  "Register the diet Org Capture template (idempotent)."
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
