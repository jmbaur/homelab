;;; -*- lexical-binding: t -*-

(require 'company)
(require 'direnv)
(require 'eglot)
(require 'evil)
(require 'evil-collection)
(require 'evil-commentary)
(require 'evil-surround)
(require 'flymake)
(require 'magit-extras)
(require 'project)
(require 'rg)
(require 'zig-mode)

(defun osc52-select-text (text)
  "Use ANSI OSC 52 escape sequence to attempt clipboard copy"
  (send-string-to-terminal
   (format "\x1b]52;c;%s\x07"
	   (base64-encode-string text t))))

(menu-bar-mode -1)
(tool-bar-mode -1)
(global-display-line-numbers-mode 1)
(global-auto-revert-mode 1)
(savehist-mode 1)
(fido-vertical-mode 1)
(rg-enable-default-bindings)

(if window-system
    (progn
      (if (fboundp 'scroll-bar-mode)
	  (scroll-bar-mode -1)))
  (setq interprogram-cut-function 'osc52-select-text))

;; Set TERM for comint-derived modes like shell-mode
(setq comint-terminfo-terminal "dumb-emacs-ansi")

;; Enable basic ANSI escape sequence support for compilation-mode
(with-eval-after-load 'compile
  (add-to-list 'compilation-environment "TERM=dumb-emacs-ansi")
  (add-hook 'compilation-filter-hook 'ansi-color-compilation-filter))

(direnv-mode 1)

(global-sops-mode 1)

(evil-set-undo-system 'undo-redo)
(evil-mode 1)
(global-evil-surround-mode 1)
(evil-commentary-mode 1)
(evil-collection-init)

;; makes magit faster for large repos
(remove-hook 'magit-status-headers-hook 'magit-insert-tags-header)
(setq magit-revision-insert-related-refs nil)
(remove-hook 'magit-status-sections-hook 'magit-insert-unpulled-from-upstream)
(remove-hook 'magit-status-sections-hook 'magit-insert-unpushed-to-upstream-or-recent)

(setq project-list-file (file-name-concat xdg-cache-home "emacs" "projects"))
(defun refresh-projects ()
  "Refresh projects file"
  (interactive)
  (let
      ((projects-dir (file-name-concat xdg-state-home "projects")))
    (if (file-exists-p projects-dir)
	(project-remember-projects-under projects-dir))))

;; scrape the projects directory, if it has not yet been scraped
(unless (file-exists-p project-list-file)
  (refresh-projects))

;; add extra keybindings for project switching and override the switch commands
(define-key project-prefix-map "g" 'rg-project)
(define-key project-prefix-map "m" 'magit-project-status)
(define-key project-prefix-map "r" 'project-recompile)
(unless (eq system-type 'darwin)
  (define-key project-prefix-map "t" 'ghostel-project))

(setq project-switch-commands '((project-find-file "Find file")
			       (project-find-dir "Find directory")
			       (rg-project "Find regexp")
			       (project-eshell "Eshell")
			       (ghostel-project "Terminal")
			       (magit-project-status "Magit")))

(define-global-abbrev "todo" "TODO(jared)")

(advice-add 'zig--run-cmd :around
	    (lambda (f cmd &optional source &rest args)
	      "Disable zig build progress"
	      (apply f cmd source (append '("--color" "off") args))))

(add-hook 'eglot-managed-mode-hook
	  (lambda ()
	    "Common LSP setup"
	    (define-key eglot-mode-map (kbd "C-c n") #'flymake-goto-next-error)
	    (define-key eglot-mode-map (kbd "C-c p") #'flymake-goto-prev-error)
	    (define-key eglot-mode-map (kbd "C-c r") #'eglot-rename)
	    (define-key eglot-mode-map (kbd "C-c a") #'eglot-code-actions)
	    (define-key eglot-mode-map (kbd "C-c .") #'company-complete)
	    (define-key eglot-mode-map (kbd "C-c C-.") #'company-complete)
	    (setq company-idle-delay nil)
	    (abbrev-mode)
	    (company-mode)
	    (eglot-inlay-hints-mode -1) ;; too noisy
	    (let ((format-on-save (cond
				   ((derived-mode-p 'python-mode) -1)
				   ((derived-mode-p 'zig-mode)
				    ;; disable zig build progress
				    (setq-local compile-command "zig build --color off")
				    ;; we use eglot-format instead
				    (zig-format-on-save-mode -1)
				    t))))
	      (when (or format-on-save t)
		(add-hook 'after-save-hook 'eglot-format nil t)))))

(add-hook 'sh-mode 'elgot-ensure)
(add-hook 'c-mode-hook 'eglot-ensure)
(add-hook 'nix-mode-hook 'eglot-ensure)
(add-hook 'rust-mode-hook 'eglot-ensure)
(add-hook 'python-mode-hook 'eglot-ensure)
(add-hook 'zig-mode-hook 'eglot-ensure)

(defun setup-term ()
  "Common terminal setup"
  ;; line numbers are not nearly useful in terminal like environments
  (line-number-mode -1)
  (display-line-numbers-mode -1))

(add-hook 'nix-repl-hook 'setup-term)
(add-hook 'shell-mode-hook 'setup-term)
(add-hook 'term-mode-hook 'setup-term)
(add-hook 'shell-command-mode-hook 'view-mode) ;; ensure we can't modify buffer for shell output
(add-hook 'eshell-load-hook 'setup-term)
(unless (eq system-type 'darwin)
  (add-hook 'ghostel-mode-hook (lambda ()
				 (setup-term)
				 (evil-ghostel-mode))))

;; ensure we load custom-file, if set
(unless (eq custom-file nil)
  (when (file-exists-p custom-file)
    (load custom-file)))
