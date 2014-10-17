(let ((dir (file-name-directory load-file-name)) (mmm nil) (mo nil) (mot nil))
  (set 'mo  (format "%s/mode.el" dir))
  (set 'mot (format "%s/template.el" dir))
  (set 'mmm (format "%s/mmm-mode" dir))
  (when (file-exists-p mo)  (load-file mo))
  (when (file-exists-p mot) (load-file mot))
  (when (file-exists-p mmm)
    (add-to-list 'load-path mmm)
    (when (load-file (format "%s/mmm-auto.el" mmm))
      (setq mmm-global-mode 'maybe)
      (mmm-add-classes
       '((mo-embedded-template
          :submode mo-template-mode
          :face mmm-default-submode-face
          :front "\\<template\s+.*?\n---+\n"
          :front-offset 0
          :back "^---+\s*end\\>"
          :back-offset 0)
         (mo-embedded-xml
          :submode sgml-mode ;nxml-mode
          :face mmm-code-submode-face ;mmm-default-submode-face
          :front "\\<lang\s+XML\\>.*?\n---+\n"
          :front-offset 0
          :back "^---+\s*end\\>"
          :back-offset 0)
         (mo-embedded-shell
          :submode shell-script-mode
          :face mmm-code-submode-face ;mmm-default-submode-face
          :front "\\<lang\s+shell\\>.*?\n---+\n"
          :front-offset 0
          :back "^---+\s*end\\>"
          :back-offset 0)
         (mo-embedded-bash
          :submode shell-script-mode
          :face mmm-code-submode-face ;mmm-default-submode-face
          :front "\\<lang\s+bash\\>.*?\n---+\n"
          :front-offset 0
          :back "^---+\s*end\\>"
          :back-offset 0)
         (mo-embedded-perl5
          :submode perl-mode
          :face mmm-code-submode-face
          :front "\\<lang\s+Perl5\\>.*?\n---+\n"
          :front-offset 0
          :back "^---+\s*end\\>"
          :back-offset 0)
         (mo-embedded-perl6
          :submode perl-mode
          :face mmm-code-submode-face
          :front "\\<lang\s+Perl6\\>.*?\n---+\n"
          :front-offset 0
          :back "^---+\s*end\\>"
          :back-offset 0)
         (mo-embedded-python
          :submode python-mode
          :face mmm-code-submode-face
          :front "\\<lang\s+python\\>.*?\n---+\n"
          :front-offset 0
          :back "^---+\s*end\\>"
          :back-offset 0)))
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-template)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-xml)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-shell)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-bash)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-perl5)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-perl6)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-python)
      t)))
