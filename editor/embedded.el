(let ((dir (file-name-directory load-file-name)) (mmm nil))
  (set 'mmm (format "%s/mmm-mode" dir))
  (when (file-exists-p mmm)
    (add-to-list 'load-path mmm)
    (load-file (format "%s/template.el" dir))
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
          :back-offset 0)))
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-template)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-shell)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-bash)
      (mmm-add-mode-ext-class 'mo-mode nil 'mo-embedded-xml)
      t)))
