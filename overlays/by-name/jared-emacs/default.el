;;; -*- lexical-binding: t -*-

(defvar xdg-cache-home (expand-file-name (or (getenv "XDG_CACHE_HOME") "~/.cache")))
(defvar xdg-config-home (expand-file-name (or (getenv "XDG_CONFIG_HOME") "~/.config")))
(defvar xdg-state-home (expand-file-name (or (getenv "XDG_STATE_HOME") "~/.local/state")))
(setq auto-save-list-file-prefix (file-name-concat user-emacs-directory "auto-save-list"))
(setq confirm-kill-emacs 'yes-or-no-p)
(setq custom-file (file-name-concat user-emacs-directory "custom.el"))
(setq fill-column 80)
(setq load-prefer-newer t)
(setq mode-line-compact 'long)
(setq native-comp-jit-compilation t)
(setq user-emacs-directory (file-name-concat xdg-state-home "emacs"))
(setq-default truncate-lines t)

(when (boundp 'native-comp-eln-load-path)
  (startup-redirect-eln-cache (file-name-concat user-emacs-directory "eln-cache")))

(let ((backup-dir (file-name-concat xdg-cache-home "emacs" "backup")))
  (unless (file-exists-p backup-dir)
    (make-directory backup-dir t))
  (setq backup-directory-alist `(("." . backup-dir))))

;; http://bling.github.io/blog/2016/01/18/why-are-you-changing-gc-cons-threshold/
(defun my-minibuffer-setup-hook ()
  (setq gc-cons-threshold most-positive-fixnum))
(defun my-minibuffer-exit-hook ()
  (setq gc-cons-threshold 800000))
(add-hook 'minibuffer-setup-hook #'my-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my-minibuffer-exit-hook)

;; https://whhone.com/posts/emacs-in-a-terminal/#tweak-for-xterm-paste
(define-advice xterm-paste
    (:before (&args) delete-active-region)
  "Delete the selected text first before pasting from xterm."
  (when (use-region-p) (delete-active-region)))

(defun osc52-select-text (text)
  "Use ANSI OSC 52 escape sequence to attempt clipboard copy"
  (send-string-to-terminal
   (format "\x1b]52;c;%s\x07"
	   (base64-encode-string text t))))

(load-theme 'modus-vivendi-tritanopia t)
(unless (and window-system (eq system-type 'darwin))
  (menu-bar-mode -1))

(use-package tool-bar
  :config
  (tool-bar-mode -1))

(if window-system
    (progn
      (set-face-attribute 'default nil :height 120) ;; sane font size
      (if (fboundp 'scroll-bar-mode)
	  (scroll-bar-mode -1)))
  (progn
    (setq ring-bell-function #'ignore)
    (xterm-mouse-mode +1)
    ;; (global-kkp-mode +1)
    (setq interprogram-cut-function 'osc52-select-text)))

(add-hook 'window-configuration-change-hook
	  (lambda ()
	    (when (not (display-graphic-p))
	      (send-string-to-terminal
	       (format "\033]0;Emacs: %s\007" (buffer-name))))))

(use-package savehist
  :config
  (savehist-mode +1))

(use-package icomplete
  :config
  (fido-vertical-mode +1))

(use-package autorevert
  :config
  (global-auto-revert-mode +1))
  
(use-package isearch
  :config
  (setq isearch-lazy-count t))

(use-package transient
  :config
  (setq transient-history-file
	(file-name-concat user-emacs-directory "transient" "history.el")))

(use-package dired
  :config
  (setq dired-dwim-target t))
  
(use-package exec-path-from-shell
  :config
  ;; Ensure environment variables from shell are present in non-shell
  ;; environments. This comes first since some packages below expect the
  ;; environment to be entirely set.
  (dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "NIX_SSL_CERT_FILE"))
    (add-to-list 'exec-path-from-shell-variables var))
  (when (or (memq window-system '(mac ns x)) (daemonp))
    (exec-path-from-shell-initialize)))

(use-package editorconfig
  :config (editorconfig-mode 1))

(use-package envrc
  :config (envrc-global-mode))

(defun evil-yank-pulse-hint (beg end &rest _)
  "Flash a temporary highlight over the yanked region."
  (when (and (called-interactively-p 'any)
	     (derived-mode-p 'prog-mode 'text-mode)) ; Only pulse in text/code
    (pulse-momentary-highlight-region beg end 'next-error)))

(use-package evil
  :init
  ;; evil requires these to be set prior to loading the evil packages
  (setq evil-symbol-word-search t)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-Y-yank-to-eol t)
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1)
  (evil-set-undo-system 'undo-redo)
  (advice-add 'evil-yank :after #'evil-yank-pulse-hint))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode +1))

(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode +1))

(use-package evil-numbers
  :after evil
  :config
  (define-key evil-normal-state-map (kbd "C-c +") #'evil-numbers/inc-at-pt)
  (define-key evil-normal-state-map (kbd "C-c -") #'evil-numbers/dec-at-pt))

(defun refresh-projects ()
  "Refresh projects file"
  (interactive)
  (let
      ((projects-dir (file-name-concat xdg-state-home "projects")))
    (if (file-exists-p projects-dir)
	(project-remember-projects-under projects-dir))))

(use-package magit
  :init
  ;; makes find-file-hook faster
  (setq vc-handled-backends '(Git))
  :config
  ;; Makes magit faster for large repos
  (remove-hook 'magit-status-headers-hook 'magit-insert-tags-header)
  (setq magit-revision-insert-related-refs nil)
  (remove-hook 'magit-status-sections-hook 'magit-insert-unpulled-from-upstream)
  (remove-hook 'magit-status-sections-hook 'magit-insert-unpushed-to-upstream-or-recent)
  (setq magit-clone-default-directory (file-name-concat xdg-state-home "projects/"))
  (add-hook 'magit-post-clone-hook #'refresh-projects))

(use-package rg
  :config
  ;; probably makes rg.el less portable, but rg-find-executable seems
  ;; broken (https://github.com/dajva/rg.el/issues/184)
  (setq rg-executable-per-connection nil)
  (rg-enable-default-bindings))

(use-package comint)

(defun setup-term ()
  "Common terminal setup"
  ;; TODO(jared): this seems to cause problems
  ;; (with-editor-export-editor)
  ;; makes terminal faster since emacs doesn't need to parse all output
  (when (not (member major-mode '(compilation-mode rg-mode vterm-mode)))
    (font-lock-mode -1))
  ;; line numbers are not nearly useful in terminal like environments
  (display-line-numbers-mode -1)
  (line-number-mode -1))

(use-package compile
  :hook
  (compilation-mode . (lambda ()
			(view-mode) ;; ensure we can't modify buffer for compilation output
			(setup-term))))

(use-package eat
  :hook setup-term)

(use-package eshell
  :hook
  (eshell-load . (lambda ()
		   (eat-eshell-mode)
		   (setup-term))))

(use-package nix
  :hook (nix-repl-mode . setup-term))

(use-package shell
  :hook
  ((shell-command-mode . (lambda ()
			   (view-mode) ;; ensure we can't modify buffer for shell output
			   (setup-term)))
   (shell-mode . setup-term)))

(use-package term
  :hook (term-mode . setup-term))

(use-package vterm
  :hook (vterm-mode . setup-term))

(if (not (eq system-type 'darwin))
    (use-package ghostel
      :hook ((ghostel-mode . setup-term)
	     (ghostel-mode . evil-ghostel-mode))))

(defun my-project-shell ()
  "Start an inferior shell in the current project's root directory.
If a buffer already exists for running a shell in the project's root,
switch to it.  Otherwise, create a new shell buffer.
With \\[universal-argument] prefix arg, create a new inferior shell buffer even
if one already exists."
  (interactive)
  (require 'comint)
  (let* ((default-directory (project-root (project-current t)))
	 (default-project-shell-name (project-prefixed-buffer-name "shell"))
	 (shell-buffer (get-buffer default-project-shell-name)))
    (if (and shell-buffer (not current-prefix-arg))
	(if (comint-check-proc shell-buffer)
	    (pop-to-buffer shell-buffer (bound-and-true-p display-comint-buffer-action))
	  (vterm shell-buffer))
      (vterm (generate-new-buffer-name default-project-shell-name)))))

(use-package project
  :config
  (setq project-list-file (file-name-concat xdg-cache-home "emacs" "projects"))
  ;; Scrape the projects directory, if it has not yet been scraped
  (unless (file-exists-p project-list-file)
    (refresh-projects))
  (setq project-switch-use-entire-map t)
  ;; Add extra keybindings for project switching and override the switch commands
  (define-key project-prefix-map "m" #'magit-project-status)
  (define-key project-prefix-map "r" #'project-recompile)
  (advice-add 'project-find-regexp :override #'rg-project)
  (advice-add 'project-shell :override #'my-project-shell))

(use-package abbrev
  :config
  (define-global-abbrev "toodoo" "TODO(jared)")
  (setq-default abbrev-mode t))

(use-package zig-mode
  :after eglot
  :config
  (advice-add 'zig--run-cmd :around
	      (lambda (f cmd &optional source &rest args)
		"Disable zig build progress"
		(apply f cmd source (append '("--color" "off") args))))
  (add-hook 'eglot-managed-mode-hook
	    (lambda ()
	      ;; disable zig build progress
	      (setq-local compile-command "zig build --color off")
	      ;; we use eglot-format instead
	      (zig-format-on-save-mode -1)))
  :hook (zig-mode . eglot-ensure))

(use-package flymake
  :init
  (add-hook 'eglot-managed-mode-hook
	    (lambda ()
	      "eglot flymake keybinds"
	      (keymap-local-set "C-c n" #'flymake-goto-next-error)
	      (keymap-local-set "C-c p" #'flymake-goto-prev-error))))

(use-package prog-mode
  :hook (prog-mode . display-line-numbers-mode))

(use-package python
  :after eglot
  :hook ((python-mode . eglot-ensure)
	 (eglot-managed-mode . (lambda ()
				 (remove-hook 'before-save-hook #'eglot-format)))))

(use-package fennel-mode
  :after eglot
  :config
  :hook ((fennel-mode . eglot-ensure)
	 (eglot-managed-mode . (lambda ()
				 (remove-hook 'before-save-hook #'eglot-format)))))
  
(use-package eglot
  :config
  (setq-default eglot-events-buffer-size 0)
  (setq eglot-code-action-indications nil)
  (add-hook 'eglot-managed-mode-hook
	    (lambda ()
	      "common LSP setup"
	      (keymap-local-set "C-c r" #'eglot-rename)
	      (keymap-local-set "C-c a" #'eglot-code-actions)
	      (add-hook 'before-save-hook #'eglot-format nil t)
	      (eglot-inlay-hints-mode -1))) ;; too noisy
  (add-to-list 'eglot-server-programs
	       '(dts-mode . ("dts-lsp" "--stdio")))
  (add-hook 'shell-mode-hook #'eglot-ensure)
  (add-hook 'c-mode-hook #'eglot-ensure)
  (add-hook 'dts-mode-hook #'eglot-ensure)
  (add-hook 'lua-mode-hook #'eglot-ensure)
  (add-hook 'nix-mode-hook #'eglot-ensure)
  (add-hook 'rust-mode-hook #'eglot-ensure))

(use-package company
  :hook
  (prog-mode eglot-managed-mode
	     (company-mode . (lambda ()
			       "Common company-mode setup"
			       (setq company-idle-delay nil)
			       (keymap-local-set "C-c ." #'company-complete)
			       (keymap-local-set "C-c C-." #'company-complete)))))

(use-package treesit
  :config
  (setq treesit-enabled-modes t))

;; Ensure we load custom-file, if set
(unless (eq custom-file nil)
  (when (file-exists-p custom-file)
    (load custom-file)))
