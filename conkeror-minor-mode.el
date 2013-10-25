;;; conkeror-minor-mode.el --- Mode for editing conkeror javascript files.

;; Copyright (C) 2013 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>>
;; URL: http://github.com/BruceConnor/conkeror-minor-mode
;; Version: 1.0
;; Keywords: programming tools
;; Prefix: conkeror
;; Separator: -

;;; Commentary:
;;
;; conkeror-minor-mode
;; ===================
;; 
;; Mode for editing conkeror javascript files.
;; 
;; Currently, this only defines a function (for sending current
;; javascript statement to be evaluated by conkeror) and binds it to a
;; key. This function is `eval-in-conkeror' bound to **C-c C-c**.
;; 
;; Installation:
;; =============
;; 
;; If you install manually, require it like this,
;; 
;;     (require 'conkeror-minor-mode)
;;     
;; then follow activation instructions below.
;; 
;; If you install from melpa just follow the activation instructions.
;; 
;; Activation
;; ==========
;; 
;; It is up to you to define when `conkeror-minor-mode' should be
;; activated. If you want it on every javascript file, just do
;; 
;;     (add-hook 'js-mode-hook 'conkeror-minor-mode)
;; 
;; If you want it only on some files, do something like:
;; 
;;     (add-hook 'js-mode-hook (lambda ()
;;                               (when (string= "your-conkerorrc-file" (buffer-file-name))
;;                                 (conkeror-minor-mode 1))))
;; 
;;

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 

;;; Change Log:
;; 1.0 - 20131025 - Created File.
;;; Code:

(defconst conkeror-version "1.0" "Version of the conkeror-minor-mode.el package.")
(defconst conkeror-version-int 1 "Version of the conkeror-minor-mode.el package, as an integer.")
(defun conkeror-bug-report ()
  "Opens github issues page in a web browser. Please send me any bugs you find, and please inclue your emacs and conkeror versions."
  (interactive)
  (message "Your conkeror-version is: %s, and your emacs version is: %s.
Please include this in your report!"
           conkeror-version emacs-version)
  (browse-url "https://github.com/BruceConnor/conkeror-minor-mode/issues/new"))
(defun conkeror-customize ()
  "Open the customization menu in the `conkeror-minor-mode' group."
  (interactive)
  (customize-group 'conkeror-minor-mode t))

(defcustom conkeror-file-path nil
  "The path to a script that runs conkeror, or to the \"application.ini\" file.

If this is nil we'll try to find an executable called
\"conkeror\" or \"conkeror.sh\" in your path."
  :type 'string
  :group 'conkeror-minor-mode)

(defun eval-in-conkeror (l r)
  "Send current javacript statement to conqueror.

This command determines the current javascript statement under
point and evaluates it in conkeror. The point of this is NOT to
gather the result (there is no return value), but to customize
conkeror directly from emacs by setting variables, defining
functions, etc.

If mark is active, send the current region instead of current
statement."
  (interactive "r")
  (message "Result was:\n%s"
           (let ((comm 
                  (concat (conkeror--command)
                          " -q -batch -e "
                          (conkeror--wrap-in ?' (js--current-statement)))))
             (message "Running:\n%s" comm)
             (shell-command-to-string comm))))

(defun conkeror--wrap-in (quote line)
  "Wrap the string in QUOTE and escape instances of QUOTE inside it."
  (let ((st (if (stringp quote) quote (char-to-string quote))))    
    (concat st
            (replace-regexp-in-string
             (regexp-quote st)
             (concat st "\\\\\\&" st)
             line t)
            st)))

(defun conkeror--command ()
  "Generate the string for the conkeror command."
  (if (stringp conkeror-file-path)
      (if (file-name-absolute-p conkeror-file-path)      
          (if (string-match "\.ini\\'" conkeror-file-path)
              (concat (executable-find "xulrunner")
                      " " (expand-file-name conkeror-file-path))
            (expand-file-name conkeror-file-path))
        (error "%S must be absolute." 'conkeror-file-path))
    (or
     (executable-find "conkeror")
     (executable-find "conkeror.sh")
     (error "Couldn't find a conkeror executable! Please set %S." 'conkeror-file-path))))

(defun js--current-statement ()
  (if (region-active-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    (let ((l (point-min))
          initial-point r)
      (save-excursion
        (skip-chars-backward "[:blank:]\n")
        (setq initial-point (point))
        (goto-char (point-min))
        (while (and (skip-chars-forward "[:blank:]\n")
                    (null r)
                    (null (eobp)))
          (when (looking-at ";")
            (forward-char 1)
            (if (>= (point) initial-point)
                (setq r (point))
              (forward-sexp 1) ;(Skip over comments and whitespace)
              (forward-sexp -1)
              (setq l (point))))
          (forward-sexp 1)))
      (buffer-substring-no-properties l r))))

;;;###autoload
(define-minor-mode conkeror-minor-mode nil nil " Conk"
  '(("" . eval-in-conkeror))
  :group 'conkeror-minor-modep)

(provide 'conkeror-minor-mode)
;;; conkeror-minor-mode.el ends here.
