(defvar mo-template-font-lock-defaults
  (list
   (list "\\([\$@%]\\)\\([\.]?\\)\\([a-z_][A-Za-z_0-9:]*\\)"
         '(1 mo-variable-name-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-face))
   (list "\\([\$@%]\\)\\([\.]?\\)\\([A-Z][A-Za-z_0-9:]*\\)"
         '(1 mo-variable-name-bold-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-bold-face))
   (list "[\$@%][\.]?[A-Za-z_][A-Za-z_0-9:]*\\(<\\)\\(.*?\\)\\(>\\)"
         '(1 mo-constant-face) '(2 mo-string-face) '(3 mo-constant-face))
   )
  "Minimal highlighting expressions for MO template")

(defvar mo-template-syntax-table
  (let ((mo-template-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\' "\"" mo-template-syntax-table) ;; single-quote used as string quote
    mo-template-syntax-table)
  "Syntax table for MO mode. See `Table of Syntax Classes'")

(define-derived-mode mo-template-mode prog-mode "MO-T"
  "Major mode for editing MO template files."
  (set-syntax-table mo-template-syntax-table)
  (set (make-local-variable 'font-lock-defaults) '(mo-template-font-lock-defaults))
  )

(provide 'mo-template-mode)
