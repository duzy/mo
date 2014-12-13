(defvar mo-template-text-face 'mo-template-text-face)
(defface mo-template-text-face
  '((t (:inherit 'mo-string-face))) "mo: template text face"
  :group 'mo)

(defun mo-template-expresion-re (re) (format "\\$(.*?%s.*?)" re))
(defun mo-template-codeblock-re (re) (format "\\${.*?%s.*?}" re))
(defun mo-template-statement-re (re) (format "^\\..*?%s.*?[\n;]?" re))
(defun mo-template-expresion-ppre (re) (mo-template-expresion-re (format "\\<\\(%s\\)\\>" re)))
(defun mo-template-codeblock-ppre (re) (mo-template-codeblock-re (format "\\<\\(%s\\)\\>" re)))
(defun mo-template-statement-ppre (re) (mo-template-statement-re (format "\\<\\(%s\\)\\>" re)))

(defvar mo-template-font-lock-defaults
  (let ()
    (list
     (list (mo-template-expresion-re mo-re-local-variable-name)         '(1 mo-variable-name-face)      '(2 mo-variable-name-bold-face) '(3 mo-variable-name-face))
     (list (mo-template-codeblock-re mo-re-local-variable-name)         '(1 mo-variable-name-face)      '(2 mo-variable-name-bold-face) '(3 mo-variable-name-face))
     (list (mo-template-statement-re mo-re-local-variable-name)         '(1 mo-variable-name-face)      '(2 mo-variable-name-bold-face) '(3 mo-variable-name-face))

     (list (mo-template-expresion-re mo-re-export-variable-name)        '(1 mo-variable-name-bold-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-bold-face))
     (list (mo-template-codeblock-re mo-re-export-variable-name)        '(1 mo-variable-name-bold-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-bold-face))
     (list (mo-template-statement-re mo-re-export-variable-name)        '(1 mo-variable-name-bold-face) '(2 mo-variable-name-bold-face) '(3 mo-variable-name-bold-face))

     (list (mo-template-expresion-re mo-re-variable-keyed)              '(1 mo-constant-face)           '(2 mo-string-face)             '(3 mo-constant-face))
     (list (mo-template-codeblock-re mo-re-variable-keyed)              '(1 mo-constant-face)           '(2 mo-string-face)             '(3 mo-constant-face))
     (list (mo-template-statement-re mo-re-variable-keyed)              '(1 mo-constant-face)           '(2 mo-string-face)             '(3 mo-constant-face))

     (cons (mo-template-expresion-re (mo-ppre mo-keyword-list))         '(1 mo-keyword-face))
     (cons (mo-template-codeblock-re (mo-ppre mo-keyword-list))         '(1 mo-keyword-face))
     (cons (mo-template-statement-re (mo-ppre mo-keyword-list))         '(1 mo-keyword-face))

     (cons (mo-template-expresion-re (mo-ppre mo-builtin-list))         '(1 mo-builtin-face))
     (cons (mo-template-codeblock-re (mo-ppre mo-builtin-list))         '(1 mo-builtin-face))
     (cons (mo-template-statement-re (mo-ppre mo-builtin-list))         '(1 mo-builtin-face))

     (cons (mo-template-expresion-re mo-re-colon-keyword)               '(1 mo-constant-face)) ;;  :keyword
     (cons (mo-template-codeblock-re mo-re-colon-keyword)               '(1 mo-constant-face)) ;;  :keyword
     (cons (mo-template-statement-re mo-re-colon-keyword)               '(1 mo-constant-face)) ;;  :keyword

     (cons (mo-template-expresion-re mo-re-export-function-name)        '(1 mo-function-name-bold-face))
     (cons (mo-template-codeblock-re mo-re-export-function-name)        '(1 mo-function-name-bold-face))
     (cons (mo-template-statement-re mo-re-export-function-name)        '(1 mo-function-name-bold-face))

     (cons (mo-template-expresion-re mo-re-local-function-name)         '(1 mo-function-name-face))
     (cons (mo-template-codeblock-re mo-re-local-function-name)         '(1 mo-function-name-face))
     (cons (mo-template-statement-re mo-re-local-function-name)         '(1 mo-function-name-face))

     (cons (mo-template-expresion-re mo-re-reference-export-name)       '(1 mo-reference-bold-face))
     (cons (mo-template-codeblock-re mo-re-reference-export-name)       '(1 mo-reference-bold-face))
     (cons (mo-template-statement-re mo-re-reference-export-name)       '(1 mo-reference-bold-face))

     (cons (mo-template-expresion-re mo-re-reference-local-name)        '(1 mo-reference-face))
     (cons (mo-template-codeblock-re mo-re-reference-local-name)        '(1 mo-reference-face))
     (cons (mo-template-statement-re mo-re-reference-local-name)        '(1 mo-reference-face))

     (list "^\\(\\.\\)[^;\n]*\\([\n;]?\\)"      '(1 mo-constant-bold-face) '(2 mo-constant-face))
     (list "\\(\\$(\\).*?\\()\\)"               '(1 mo-constant-face)      '(2 mo-constant-face))
     (list "\\(\\${\\).*?\\(}\\)"               '(1 mo-constant-face)      '(2 mo-constant-face))

     (cons "\\(.*?\\)\\$(.*?)"                  '(1 mo-template-text-face)) ;; the text before $()
     (cons "\\(.*?\\)\\${.*?}"                  '(1 mo-template-text-face)) ;; the text before ${}
     (cons "\\(?:.*?\\$(.*?)\\)+\\(.+?\\)\n"    '(1 mo-template-text-face)) ;; the text after $()
     (cons "\\(?:.*?\\${.*?}\\)+\\(.+?\\)\n"    '(1 mo-template-text-face)) ;; the text after ${}
     (cons "^\\([^\\.][^\n]*\\)"                '(1 mo-template-text-face)) ;; the text without $() or ${}
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
