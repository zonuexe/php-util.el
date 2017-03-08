;;; php-util.el --- Utility for editing PHP -*- mode: lexical-binding: t -*-

;; Copyright (C) 2016 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 4 Oct 2016
;; Version: 0.0.1
;; Keywords: languages php
;; Homepage: https://github.com/zonuexe/emacs-copyit
;; Package-Requires: ((emacs "24") (cl-lib "0.5") (php-mode "1.15") (f "0.16.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; ヾ(〃＞＜)ﾉﾞ☆

;; Add to your .emacs file (~/.emacs.d/init.el).
;;
;;     (add-hook 'php-mode-hook
;;               #'(lambda ()
;;                   (local-set-key (kbd "C-c C--") 'php-util-insert-current-class)
;;                   (local-set-key (kbd "C-c C-=") 'php-util-insert-current-namespace)))

;;; Code:

(require 'f)
(require 'php-mode)
(require 'regexp-opt)

(defgroup php-util nil
  "Utility for editiong PHP."
  :tag "PHP utility"
  :prefix "php-util-"
  :group 'tools
  :group 'php)

(defcustom php-util-class-suffix-when-insert "::"
  "Suffix for inserted class."
  :type 'string)

(defcustom php-util-namespace-suffix-when-insert "\\"
  "Suffix for inserted namespace."
  :type 'string)

(defcustom php-util-thingatpt-php-token-script "
$point = $_SERVER['argv'][1];

$offset = 0;
foreach (token_get_all(file_get_contents('php://stdin')) as $token) {
    $s = is_array($token) ? $token[1] : $token;
    $l = mb_strlen($s);
    if ($offset + $l > $point) {
        echo $s;
        exit;
    }

    $offset += $l;
}
"
  "PHP tokenize script for `thing-at-point'.")

(defvar php-util--re-namespace-pattern
  (php-create-regexp-for-classlike "namespace"))

(defvar php-util--re-classlike-pattern
  (php-create-regexp-for-classlike (regexp-opt '("class" "interface" "trait"))))

(defconst php-util--re-function-or-method-pattern
  "^\\s-*\\(?:\\(?:public\\|private\\|static\\|final\\)\\s-*\\)*function\\s-+\\(\\(?:\\sw\\|\\s_\\)+\\)\\s-*(")

;;;###autoload
(defun php-util-copyit-fqsen ()
  "Copy/kill class/method FQSEN."
  (interactive)
  (let ((namespace  (or (php-util-get-current-element php-util--re-namespace-pattern) ""))
        (class      (or (php-util-get-current-element php-util--re-classlike-pattern) ""))
        (namedfunc  (php-util-get-current-element php-util--re-function-or-method-pattern)))
    (kill-new (concat (if (string= namespace "") "" (concat "\\" namespace))
                      (if (string= class "") "" (concat "\\" class "::"))
                      (if (string= namedfunc "") "" (concat namedfunc "()"))))))

;;;###autoload
(defun php-util-run-php-builtin-web-server (dir-or-router hostname port &optional document-root)
  "Run PHP Builtin-server."
  (interactive
   (let ((insert-default-directory t)
         (d-o-r (read-file-name "Document root or Script: " default-directory)))
     (list
      d-o-r
      (read-string "Hostname: " "0.0.0.0")
      (read-number "Port:" 3939)
      (if (f-dir? d-o-r)
          dir-or-router
        (let ((root-input (read-file-name "Document root: " (f-dirname d-o-r))))
          (if (f-dir? root-input) root-input (f-dirname root-input)))))))
  (let* ((default-directory (or document-root
                                (if (f-dir? dir-or-router)
                                    dir-or-router
                                  default-directory)))
         (opt-t (if (f-dir? dir-or-router) "-t " ""))
         (pattern (eval `(rx bos ,(getenv "HOME"))))
         (short-dirname (replace-regexp-in-string pattern "~" dir-or-router))
         (buf-name (format "php -S %s:%s %s%s" hostname port opt-t short-dirname)))
    (message "Run PHP built-in server: %s" buf-name)
    (make-comint buf-name "php" nil "-S"
                 (format "%s:%s" hostname port)
                 (if (f-dir? dir-or-router) "-t" "")
                 (concat dir-or-router (if (f-dir? dir-or-router) "" "/")))
    (display-buffer (format "*%s*" buf-name))))

;;;###autoload
(defun php-util-get-current-element (re-pattern)
  "Return backward matched element by RE-PATTERN."
  (save-excursion
    (when (re-search-backward re-pattern nil t)
      (match-string-no-properties 1))))

;;;###autoload
(defun php-util-insert-current-class ()
  "Insert current class name if cursor in class context."
  (interactive)
  (let ((matched (php-util-get-current-element php-util--re-classlike-pattern)))
    (when matched
      (insert (concat matched php-util-class-suffix-when-insert)))))

;;;###autoload
(defun php-util-insert-current-namespace ()
  "Insert current namespace if cursor in in namespace context."
  (interactive)
  (let ((matched (php-util-get-current-element php-util--re-namespace-pattern)))
    (when matched
      (insert (concat matched php-util-namespace-suffix-when-insert)))))

;;;###autoload
(defun php-util-thingatpt-php-token (&optional point)
  "Return the PHP Token at `POINT'."
  (unless point (setq point (point)))
  (unless (integerp point)
    (error "`point' is not integer"))
  (let ((in (current-buffer)) out)
    (with-temp-buffer
      (setq out (current-buffer))
      (with-current-buffer in
        (call-process-region
         (point-min) (point-max)
         "php" nil out nil "-r" php-util-thingatpt-php-token-script (number-to-string point)))
      (buffer-substring-no-properties (point-min) (point-max)))))

;;;###autoload
(defun php-util-register-thing-at-point ()
  "Register functions for `thing-at-point'."
  (put 'php-token 'thing-at-point 'php-util-thingatpt-php-token))

(provide 'php-util)
;;; php-util.el ends here
