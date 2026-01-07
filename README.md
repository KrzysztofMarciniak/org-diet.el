# org-diet.el
![screenshot](screenshot.png)
A really simple diet tracking made with emacs lisp and capture templates.

1. Place `org-diet.el` in your `~/.emacs.d/lisp/` or repository folder.
2. Load it in your init:

```elisp
(add-to-list 'load-path "~/path/to/repo/")
(require 'org-diet)
```

3. Invoke the capture with(M-x org-capture):

```
C-c c d
```

4. Daily files are created at:

```
~/org/diet/YYYY-MM-DD.org
```

5. Table automatically includes:

```
| Time   | Food | Calories |
|--------|------|----------|
|        |      |          |

Total calories: %(vsum(@I$3..@II$3))
```

* `:prepend t` inserts at the first empty row.
* Returns `(BUFFER . POINT)` to prevent the previous `eq` error.
