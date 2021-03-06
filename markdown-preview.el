;;; markdown-preview.el --- Github flavored markdown preview for Emacs  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  chuntaro

;; Author: chuntaro <chuntaro@sakura-games.jp>
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.5"))
;; Keywords: http, markdown
;; Homepage: https://github.com/chuntaro/markdown-preview

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

;; This is the Markdown (e.g. README.md) preview using the API of Github.
;;
;; Usage
;;
;; (add-to-list 'load-path "/full/path/where/markdown-preview.el/in/")
;; (autoload 'markdown-preview "markdown-preview" "Github flavored markdown preview for Emacs" t)
;;
;; Execute M-x markdown-preview while editing the Markdown.
;; For example README.md.html is created that it is being edited the README.md.
;;
;; TODO: asynchronous
;; TODO: review CSS

;;; Code:

(require 'url-http)
(require 'browse-url)
(eval-when-compile (require 'cl))
(require 'cl-lib)

(defconst markdown-preview-version "0.2.0")

(defgroup markdown-preview nil
  "Github flavored markdown preview for Emacs."
  :prefix "markdown-preview-"
  :group 'text)

(defcustom markdown-preview-api-url "https://api.github.com/markdown/raw"
  "URL of Github markdown API."
  :type 'string
  :group 'markdown-preview)

(defcustom markdown-preview-charset "utf-8"
  "Character set of when to request API."
  :type 'string
  :group 'markdown-preview)

(defcustom markdown-preview-content-type "text/plain"
  "MIME type of when to request API."
  :type 'string
  :group 'markdown-preview)

(defvar url-http-response-status)

(defun markdown-preview-http-post (url data charset extra-headers)
  (let ((url-request-method "POST")
	(url-request-data data)
	(url-request-extra-headers extra-headers)
	(url-mime-charset-string charset))
    (let (header
	  data
	  status)
      (with-current-buffer
	  (url-retrieve-synchronously url)
	(setq status url-http-response-status)
	(princ status)
	(goto-char (point-min))
	(if (search-forward-regexp "^$" nil t)
	    (setq header (buffer-substring-no-properties (point-min) (point))
		  data (buffer-substring-no-properties (1+ (point)) (point-max)))
	  (setq data (buffer-substring-no-properties (point-min) (point-max)))))
      (cl-values data header status))))

(defvar markdown-preview-data-root (file-name-directory load-file-name))

(defvar markdown-preview-application-name "markdown-preview")
(defvar markdown-preview-template-shtml (concat markdown-preview-application-name ".shtml"))
(defvar markdown-preview-replacement-text (concat "<!--#include virtual=\""
						  markdown-preview-application-name "\" -->"))

(defun markdown-preview-github-api-markdown ()
  (cl-multiple-value-bind (data _ _)
      (markdown-preview-http-post markdown-preview-api-url
		    (buffer-substring-no-properties (point-min) (point-max))
		    markdown-preview-charset
		    `(("Content-Type" . ,(format "%s; charset=%s"
						 markdown-preview-content-type
						 markdown-preview-charset))))
    (let ((exportname (concat (or (buffer-file-name)
				  (make-temp-name
				   (expand-file-name markdown-preview-application-name
						     temporary-file-directory)))
			      ".html")))
      (with-temp-file exportname
	(insert-file-contents-literally (expand-file-name markdown-preview-template-shtml
							  markdown-preview-data-root))
	(goto-char (point-min))
	(if (search-forward-regexp "<title>.*</title>" nil t)
	    (replace-match (concat "<title>" (file-name-nondirectory exportname) "</title>") t t))
	(goto-char (point-min))
	(if (search-forward markdown-preview-replacement-text nil t)
	    (replace-match data t t)))
      exportname)))

;;;###autoload
(defun markdown-preview ()
  "Github flavored markdown preview for Emacs"
  (interactive)
  (browse-url (markdown-preview-github-api-markdown)))

;;;###autoload
(defalias 'mp-preview 'markdown-preview)

(provide 'markdown-preview)
;;; markdown-preview.el ends here
