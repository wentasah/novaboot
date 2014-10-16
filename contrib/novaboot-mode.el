;;; novaboot-mode.el --- Major mode for novaboot scripts

;; Copyright (C) 2014  Michal Sojka

;; Author: Michal Sojka <sojkam1@fel.cvut.cz>
;; Keywords: languages, tools, files

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

;;

;;; Code:


(defvar novaboot-mode-syntax-table
  (let ((table (make-syntax-table))
	(list (list ?\# "<"
		    ?\n ">#"
		    ?\" "\"\""
		    ?\' "\"'"
		    ?\` "\"`"
		    ?=  "."
		    )))
    (while list
      (modify-syntax-entry (pop list) (pop list) table))
    table))

(defvar novaboot-mode-font-lock-keywords)
(setq novaboot-mode-font-lock-keywords
  `(("^#.*" . font-lock-comment-face)
    ("^load\\>.*\\(<<EOF\\)\n\\(\\(?:.*\n\\)*?\\)\\(EOF\\)\n"
     (1 font-lock-preprocessor-face)
     (2 font-lock-string-face)
     (3 font-lock-preprocessor-face))
    ("^\\(load\\)\\s-+\\([^ \n\t]*\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face))
    ("^load\\>.*?< \\(.*\\)"
     (1 font-lock-string-face))
    ("^\\(run\\|uboot\\)\\>" . font-lock-keyword-face)
    ("^\\([A-Z_]+\\)=" (1 font-lock-variable-name-face))
    ("\\$\\(NB_\\(MYIP\\|PREFIX\\)\\)\\>" (1 font-lock-variable-name-face))
    ))

(defun novaboot-font-lock-extend-region ()
  (let ((changed nil))
    (goto-char font-lock-beg)
    (when (re-search-forward "^EOF\\>" font-lock-end t)
      (re-search-backward "<<EOF$" nil t)
      (when (< (point) font-lock-beg)
	(setq changed t font-lock-beg (point))))
    (goto-char font-lock-end)
    (when (re-search-backward "<<EOF$" font-lock-beg t)
      (re-search-forward "^EOF\\>" nil t)
      (when (> (point) font-lock-end)
	(setq changed t font-lock-end (point))))
    changed))

(defun novaboot-post-self-insert ()
  (when (looking-back "<<$" (- (point) 2))
    (insert "EOF\n\nEOF")
    (previous-line)))

;;;###autoload
(define-derived-mode novaboot-mode prog-mode "Novaboot"
  :syntax-table novaboot-mode-syntax-table
  (set (make-local-variable 'font-lock-defaults)
       '(novaboot-mode-font-lock-keywords t))
  (set (make-local-variable 'font-lock-verbose) t)
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-end) "")
  (setq font-lock-multiline t)
  (add-hook 'font-lock-extend-region-functions 'novaboot-font-lock-extend-region)
  (add-hook 'post-self-insert-hook 'novaboot-post-self-insert))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("/\\.novaboot\\'" . perl-mode))
  (add-to-list 'interpreter-mode-alist '("novaboot" . novaboot-mode)))


(provide 'novaboot-mode)
;;; novaboot-mode.el ends here
