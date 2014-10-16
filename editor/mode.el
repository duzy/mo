(require 'perl-mode)

(defvar mo-keyword-face 'mo-keyword-face)
(defface mo-keyword-face
  '((t (:inherit 'font-lock-keyword-face))) "mo: keyword face"
  :group 'mo)

(defvar mo-builtin-face 'mo-builtin-face)
(defface mo-builtin-face
  '((t (:inherit 'font-lock-builtin-face))) "mo: builtin face"
  :group 'mo)

(defvar mo-string-name-face 'mo-string-name-face)
(defface mo-string-name-face
  '((t (:inherit 'font-lock-string-name-face))) "mo: string face"
  :group 'mo)

(defvar mo-variable-name-face 'mo-variable-name-face)
(defface mo-variable-name-face
  '((t (:inherit 'font-lock-variable-name-face))) "mo: variable face"
  :group 'mo)

(defvar mo-function-name-face 'mo-function-name-face)
(defface mo-function-name-face
  '((t (:inherit 'font-lock-function-name-face))) "mo: function face"
  :group 'mo)

(defvar mo-reference-face 'mo-reference-face)
(defface mo-reference-face
  '((t (:inherit 'font-lock-reference-face))) "mo: reference face"
  :group 'mo)

(defvar mo-constant-face 'mo-constant-face)
(defface mo-constant-face
  '((t (:inherit 'font-lock-constant-face))) "mo: constant face"
  :group 'mo)

(defvar mo-keyword-list
  '("if" "else" "elsif" "unless" "for" "any" "while" "until" "yield" "str" "def" "end"
    "le" "ge" "lt" "gt" "eq" "ne" "cmp" "not" "and" "or" "use" "var" "return" "as"
    "template" "lang" "class" "method" "in"))

(defvar mo-builtin-list
  '("new" "print" "say" "die" "exit" "open" "slurp" "shell" "system" "cwd" "basename" "dirname"
    "isreg" "isdir" "isdev" "islink" "isreadable" "iswritable" "isexecutable" "isnull" "defined"
    "list" "hash" "elems" "splice" "slice" "split" "join" "concat" "chars" "index" "rindex"
    "endswith" "startswith" "substr" "strip" "addprefix" "addsuffix" "addinfix"
    "load" "init" "getattr" "setattr"))

(defun mo-ppre (re) (format "\\<\\(%s\\)\\>[^_]" (regexp-opt re)))

(defvar mo-font-lock-defaults
  (list
   (cons "[\$@%][\.]?[A-Za-z_][A-Za-z_0-9:]*\\(<.*?>\\)?" mo-variable-name-face)
   (cons (mo-ppre mo-keyword-list) mo-keyword-face)
   (cons (mo-ppre mo-builtin-list) mo-builtin-face)
   (cons "\s\\(:[A-Za-z_][A-Za-z_0-9]*\\)" '(1 mo-constant-face)) ;;  :keyword
   (cons "\\([A-Za-z_][A-Za-z_0-9]*\\)(" '(1 mo-function-name-face))
   (cons "[A-Za-z_][A-Za-z_0-9]*" mo-reference-face)
   )
  "Minimal highlighting expressions for MO mode")

(defvar mo-syntax-table
  (let ((mo-syntax-table (make-syntax-table)))
    ;;(modify-syntax-entry ?\" "\"" mo-syntax-table)
    (modify-syntax-entry ?\' "\"" mo-syntax-table) ;; single-quote used as string quote
    ;;(modify-syntax-entry ?< "(" mo-syntax-table)
    ;;(modify-syntax-entry ?> ")" mo-syntax-table)
    mo-syntax-table)
  "Syntax table for MO mode. See `Table of Syntax Classes'")

(defvar mo-other-file-alist
  '(("\\.mo$" (".mo")) ("\\.MO$" (".MO")))
  "Alist of extensions to find given the current file's extension")

(defvar mo-mode-hook nil
  "Normal hook to run when entering MO mode.")

(defvar mo-mode-map
  (let ((mo-mode-map (make-sparse-keymap)))
    (define-key mo-mode-map [S-iso-lefttab] 'ff-find-other-file)
    (define-key mo-mode-map [tab] 'mo-indent-command)
    (define-key mo-mode-map "\C-i" 'mo-indent-command)
    mo-mode-map)
  "Keymap for MO major mode")

(defun mo-editing-template-p ()
  (or (looking-at "^---+")
      (looking-at "^---+[:space:]*end")
      (looking-back "^---+\n")
      (let ((tmp nil) (beg nil) (end nil) (lang nil))
        (save-excursion
          (when (set 'beg (re-search-backward "^---+\n" nil t))
            (when (looking-back "lang[:space:]+\\([A-Za-z_0-9]+\\)[:space:]+.*?\n")
              (set 'lang (match-data 1)) (message lang))
            (set 'tmp (re-search-forward "^---+[:space:]*end" nil t))))
        (set 'end (save-excursion (re-search-forward "^---+[:space:]*end" nil t)))
        (and beg (or (and tmp end (= tmp end)) (and (not tmp) (not end)))))
      nil))

(defun mo-indent-command (&optional arg)
  "Indent MO code in the active region or current line."
  (interactive)
  (if (mo-editing-template-p)
      (progn
       (message "template"))
    (perl-indent-command arg)))

(define-derived-mode mo-mode prog-mode "MO"
  "Major mode for editing .mo files."
  (set-syntax-table mo-syntax-table)
  (set (make-local-variable 'font-lock-defaults) '(mo-font-lock-defaults))
  (set (make-local-variable 'ff-other-file-alist) 'mo-other-file-alist)
  (set (make-local-variable 'comment-start) "#")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'comment-padding) "")
  ;(add-to-list 'align-c++-modes 'mo-mode)
  )

(progn
  (add-to-list 'auto-mode-alist '("\\.MO\\'" . mo-mode))
  (add-to-list 'auto-mode-alist '("\\.mo\\'" . mo-mode)))

(provide 'mo-mode)
