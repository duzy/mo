;;
;;      Duzy Chan <code@duzy.info>
;; 
(require 'perl-mode)

(defvar mo-keyword-face 'mo-keyword-face)
(defface mo-keyword-face
  '((t (:inherit 'font-lock-keyword-face))) "mo: keyword face"
  :group 'mo)

(defvar mo-builtin-face 'mo-builtin-face)
(defface mo-builtin-face
  '((t (:inherit 'font-lock-builtin-face))) "mo: builtin face"
  :group 'mo)

(defvar mo-warning-face 'mo-warning-face)
(defface mo-warning-face
  '((t (:inherit 'font-lock-warning-face))) "mo: warning face"
  :group 'mo)

(defvar mo-string-face 'mo-string-face)
(defface mo-string-face
  '((t (:inherit 'font-lock-string-face))) "mo: string face"
  :group 'mo)

(defvar mo-string-bold-face 'mo-string-bold-face)
(defface mo-string-bold-face
  '((t (:inherit 'mo-string-face))) "mo: bold string face"
  :group 'mo)

(defvar mo-type-face 'mo-type-face)
(defface mo-type-face
  '((t (:inherit 'font-lock-type-face))) "mo: type face"
  :group 'mo)

(defvar mo-type-bold-face 'mo-type-bold-face)
(defface mo-type-bold-face
  '((t (:inherit 'mo-type-face :weight bold))) "mo: bold type face"
  :group 'mo)

(defvar mo-variable-name-face 'mo-variable-name-face)
(defface mo-variable-name-face
  '((t (:inherit 'font-lock-variable-name-face))) "mo: variable face"
  :group 'mo)

(defconst vc (face-foreground font-lock-variable-name-face))
(defvar mo-variable-name-bold-face 'mo-variable-name-bold-face)
(defface mo-variable-name-bold-face
  '((t (:inherit 'mo-variable-name-face :weight bold))) "mo: bold variable face"
  :group 'mo)

(defvar mo-function-name-face 'mo-function-name-face)
(defface mo-function-name-face
  '((t (:inherit 'font-lock-function-name-face))) "mo: function face"
  :group 'mo)

(defvar mo-function-name-bold-face 'mo-function-name-bold-face)
(defface mo-function-name-bold-face
  '((t (:inherit 'mo-function-name-face :weight bold))) "mo: bold function face"
  :group 'mo)

(defvar mo-reference-face 'mo-reference-face)
(defface mo-reference-face
  '((t (:inherit 'font-lock-reference-face :foreground "DimGray"))) ;;DarkGray, DimGray, gray
  "mo: reference face"
  :group 'mo)

(defvar mo-reference-bold-face 'mo-reference-bold-face)
(defface mo-reference-bold-face
  '((t (:inherit 'mo-reference-bold-face :weight bold))) "mo: bold reference face"
  :group 'mo)

(defvar mo-constant-face 'mo-constant-face)
(defface mo-constant-face
  '((t (:inherit 'font-lock-constant-face))) "mo: constant face"
  :group 'mo)

(defvar mo-constant-bold-face 'mo-constant-bold-face)
(defface mo-constant-bold-face
  '((t (:inherit 'mo-constant-face :weight bold))) "mo: bold constant face"
  :group 'mo)

;; font-lock-builtin-face 	font-lock-comment-delimiter-face
;; font-lock-comment-face 	font-lock-constant-face
;; font-lock-doc-face 	font-lock-function-name-face
;; font-lock-keyword-face 	font-lock-negation-char-face
;; font-lock-preprocessor-face 	font-lock-reference-face
;; font-lock-string-face 	font-lock-syntactic-face-function
;; font-lock-type-face 	font-lock-variable-name-face
;; font-lock-warning-face

(defvar mo-keyword-list
  '("if" "else" "elsif" "unless" "for" "any" "while" "until" "yield" "str" "def" "end"
    "le" "ge" "lt" "gt" "eq" "ne" "cmp" "not" "and" "or" "use" "var" "return" "as"
    "template" "lang" "class" "method" "in"))

(defvar mo-builtin-list
  '("new" "print" "say" "die" "exit" "open" "slurp" "shell" "system" "cwd" "basename" "dirname"
    "isreg" "isdir" "isdev" "islink" "isreadable" "iswritable" "isexecutable" "isnull" "defined"
    "list" "hash" "elems" "splice" "slice" "split" "join" "concat" "chars" "index" "rindex"
    "endswith" "startswith" "substr" "strip" "addprefix" "addsuffix" "addinfix"
    "load" "init" "getattr" "setattr" "me" "null"))

(defun mo-ppre (re) (format "\\<\\(%s\\)\\>[^_]" (regexp-opt re)))
(defun mo-idre () nil)

(defvar mo-font-lock-defaults
  (list
   (list "\\([\$@%]\\)\\([\.]?\\)\\([a-z_][A-Za-z_0-9:]*\\)"
         '(1 mo-variable-name-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-face))
   (list "\\([\$@%]\\)\\([\.]?\\)\\([A-Z][A-Za-z_0-9:]*\\)"
         '(1 mo-variable-name-bold-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-bold-face))
   (list "[\$@%][\.]?[A-Za-z_][A-Za-z_0-9:]*\\(<\\)\\(.*?\\)\\(>\\)"
         '(1 mo-constant-face) '(2 mo-string-face) '(3 mo-constant-face))

   (cons "class\s+\\([A-Z][A-Za-z_0-9]*\\)" '(1 mo-type-bold-face))
   (cons "class\s+\\([a-z_][A-Za-z_0-9]*\\)" '(1 mo-type-face))

   (cons "lang\s+\\([a-z_][A-Za-z_0-9]*\\)" '(1 mo-reference-bold-face))

   (cons (mo-ppre mo-keyword-list) '(1 mo-keyword-face))
   (cons (mo-ppre mo-builtin-list) '(1 mo-builtin-face))
   (cons "\s\\(:[A-Za-z_][A-Za-z_0-9]*\\)\\>" '(1 mo-constant-face)) ;;  :keyword
   (cons "\\([A-Z][A-Za-z_0-9]*\\)(" '(1 mo-function-name-bold-face))
   (cons "\\([a-z_][A-Za-z_0-9]*\\)(" '(1 mo-function-name-face))
   (cons "[A-Z][A-Za-z_0-9]*" mo-reference-bold-face)
   (cons "[a-z_][A-Za-z_0-9]*" mo-reference-face)
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
