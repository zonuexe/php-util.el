;;; php-util.el --- Utility for editing PHP -*- mode: lexical-binding: t -*-

;; Copyright (C) 2016 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 4 Oct 2016
;; Version: 0.0.1
;; Keywords: languages php
;; Homepage: https://github.com/zonuexe/emacs-copyit
;; Package-Requires: ((emacs "24") (cl-lib "0.5") (php-mode "1.15"))

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

(defvar php-util--re-namespace-pattern
  (php-create-regexp-for-classlike "namespace"))

(defvar php-util--re-classlike-pattern
  (php-create-regexp-for-classlike (regexp-opt '("class" "interface" "trait"))))

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

(provide 'php-util)
;;; php-util.el ends here
