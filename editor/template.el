(defun mo-template-expresion-re (re) (format "\\$(.*?%s.*?)" re))
(defun mo-template-statement-re (re) (format "^\\..*?%s.*?[\n;]?" re))
(defun mo-template-statement-ppre (re) (mo-template-statement-re (format "\\<\\(%s\\)\\>" re)))

(defvar mo-template-font-lock-defaults
  (let ((re-variable-name1 "\\([\$@%]\\)\\([\\.]?\\)\\([a-z_][A-Za-z_0-9:]*\\)")
        (re-variable-name2 "\\([\$@%]\\)\\([\\.]?\\)\\([A-Z][A-Za-z_0-9:]*\\)"))
    (list
     (list (mo-template-expresion-re re-variable-name1)
           '(1 mo-variable-name-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-face))
     (list (mo-template-expresion-re re-variable-name2)
           '(1 mo-variable-name-bold-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-bold-face))

     (list (mo-template-statement-re re-variable-name1)
           '(1 mo-variable-name-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-face))
     (list (mo-template-statement-re re-variable-name2)
           '(1 mo-variable-name-bold-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-bold-face))
     (list (mo-template-statement-re "[\\$@%][\\.]?[A-Za-z_][A-Za-z_0-9:]*\\(<\\)\\(.*?\\)\\(>\\)")
           '(1 mo-constant-face) '(2 mo-string-face) '(3 mo-constant-face))

     (cons (mo-template-expresion-re (mo-ppre mo-keyword-list)) '(1 mo-keyword-face))
     (cons (mo-template-statement-re (mo-ppre mo-keyword-list)) '(1 mo-keyword-face))

     (list "^\\(\\.\\)[^;\n]*\\([\n;]?\\)" '(1 mo-constant-bold-face) '(2 mo-constant-bold-face))
     (list "\\(\\$(\\).*?\\()\\)" '(1 mo-constant-face) '(2 mo-constant-face))
     ))
  "Minimal highlighting expressions for MO template")

(defvar mo-template-syntax-table
  (let ((mo-template-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\' "\"" mo-template-syntax-table) ;; single-quote used as string quote
    mo-template-syntax-table)
  "Syntax table for MO mode. See `Table of Syntax Classes'")

(define-derived-mode mo-template-mode prog-mode "MOT"
  "Major mode for editing MO template files."
  (set-syntax-table mo-template-syntax-table)
  (set (make-local-variable 'font-lock-defaults) '(mo-template-font-lock-defaults))
  )

(provide 'mo-template-mode)
