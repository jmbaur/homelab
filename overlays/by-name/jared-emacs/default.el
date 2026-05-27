;;; -*- lexical-binding: t -*-

(setq confirm-kill-emacs 'yes-or-no-p)
(setq dired-dwim-target t)
(setq direnv-always-show-summary nil)
(setq evil-symbol-word-search t)
(setq evil-want-C-u-scroll t)
(setq evil-want-Y-yank-to-eol t)
(setq evil-want-keybinding nil)
(setq inhibit-splash-screen t)
(setq isearch-lazy-count t)
(setq load-prefer-newer t)
(setq mode-line-compact 'long)
(setq native-comp-jit-compilation t)
(setq-default eglot-events-buffer-size 0)
(setq-default truncate-lines t)

(setq xdg-cache-home (expand-file-name (or (getenv "XDG_CACHE_HOME") "~/.cache")))
(setq xdg-config-home (expand-file-name (or (getenv "XDG_CONFIG_HOME") "~/.config")))
(setq xdg-state-home (expand-file-name (or (getenv "XDG_STATE_HOME") "~/.local/state")))
(setq user-emacs-directory (file-name-concat xdg-state-home "emacs"))
(setq custom-file (file-name-concat user-emacs-directory "custom.el"))
(setq auto-save-list-file-prefix (file-name-concat user-emacs-directory "auto-save-list"))
(setq transient-history-file (file-name-concat user-emacs-directory "transient" "history.el"))

(when (boundp 'native-comp-eln-load-path)
  (startup-redirect-eln-cache (file-name-concat user-emacs-directory "eln-cache")))

(let ((backup-dir (file-name-concat xdg-cache-home "emacs" "backup")))
  (unless (file-exists-p backup-dir)
    (make-directory backup-dir t))
  (setq backup-directory-alist `(("." . backup-dir))))

;; Ensure environment variables from shell are present in non-shell
;; environments. This comes first since some packages below expect the
;; environment to be entirely set.
(require 'exec-path-from-shell)
(dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "NIX_SSL_CERT_FILE"))
  (add-to-list 'exec-path-from-shell-variables var))
(when (or (memq window-system '(mac ns x)) (daemonp))
  (exec-path-from-shell-initialize))

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

(unless (and window-system (eq system-type 'darwin))
  (menu-bar-mode -1))
(tool-bar-mode -1)
(global-display-line-numbers-mode 1)
(global-auto-revert-mode 1)
(savehist-mode 1)
(fido-vertical-mode 1)
(editorconfig-mode 1)
(rg-enable-default-bindings)

(if window-system
    (progn
      (if (fboundp 'scroll-bar-mode)
	  (scroll-bar-mode -1)))
  (progn
   (xterm-mouse-mode t)
   (setq interprogram-cut-function 'osc52-select-text)))

;; Set TERM for comint-derived modes like shell-mode
(setq comint-terminfo-terminal "dumb-emacs-ansi")

;; Enable basic ANSI escape sequence support for compilation-mode
(with-eval-after-load 'compile
  (add-to-list 'compilation-environment "TERM=dumb-emacs-ansi")
  (add-hook 'compilation-filter-hook 'ansi-color-compilation-filter))

(direnv-mode 1)

(evil-set-undo-system 'undo-redo)
(evil-mode 1)
(global-evil-surround-mode 1)
(evil-commentary-mode 1)
(evil-collection-init)

(defun setup-theme (frame)
  "Select theme based on the terminal's background mode (also works outside of terminal)."
  (with-selected-frame frame
    (let ((bg-mode (frame-parameter frame 'background-mode)))
      (if (eq bg-mode 'dark)
          (load-theme 'modus-vivendi t)
        (load-theme 'modus-operandi t)))))

;; Apply theme when a new frame is created (essential for emacs-daemon)
(add-hook 'after-make-frame-functions 'setup-theme)

;; Also run for the initial frame
(setup-theme (selected-frame))

;; Makes magit faster for large repos
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

;; Scrape the projects directory, if it has not yet been scraped
(unless (file-exists-p project-list-file)
  (refresh-projects))

(defun project-term ()
  "Launch terminal in current project"
  (interactive)
  (if (eq system-type 'darwin)
      (let ((default-directory (project-root (project-current t))))
	(vterm (format "term-%s" (car (last (file-name-split default-directory) 2)))))
    (ghostel-project)))

;; Add extra keybindings for project switching and override the switch commands
(define-key project-prefix-map "g" #'rg-project)
(define-key project-prefix-map "m" #'magit-project-status)
(define-key project-prefix-map "r" #'project-recompile)
(define-key project-prefix-map "t" #'eat-project)

(setq project-switch-commands '((project-find-file "Find file")
				(project-find-dir "Find directory")
				(rg-project "Find regexp")
				(project-eshell "Eshell")
				(eat-project "Terminal")
				(magit-project-status "Magit")))

(define-global-abbrev "toodoo" "TODO(jared)")
(setq-default abbrev-mode t)

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
	    (add-hook 'before-save-hook #'eglot-format nil t)
	    (setq company-idle-delay nil)
	    (company-mode)
	    (eglot-inlay-hints-mode -1) ;; too noisy
	    (cond
	     ((or (derived-mode-p 'python-mode) (derived-mode-p 'fennel-mode))
	      (remove-hook 'before-save-hook #'eglot-format))
	     ((derived-mode-p 'zig-mode)
	      ;; disable zig build progress
	      (setq-local compile-command "zig build --color off")
	      ;; we use eglot-format instead
	      (zig-format-on-save-mode -1)))))

(add-to-list 'eglot-server-programs
	     '(dts-mode . ("dts-lsp" "--stdio")))

(setq major-mode-remap-alist
 '((yaml-mode . yaml-ts-mode)
   (sh-mode . bash-ts-mode) ;; probably don't want to do this
   (js-mode . js-ts-mode)
   (typescript-mode . typescript-ts-mode)
   (json-mode . json-ts-mode)
   (css-mode . css-ts-mode)
   (c-mode . c-ts-mode)
   (lua-mode . lua-ts-mode)
   (rust-mode . rust-ts-mode)
   (python-mode . python-ts-mode)))

(add-hook 'bash-ts-mode-hook #'eglot-ensure)
(add-hook 'c-ts-mode-hook #'eglot-ensure)
(add-hook 'dts-mode-hook #'eglot-ensure)
(add-hook 'fennel-mode-hook #'eglot-ensure)
(add-hook 'lua-ts-mode-hook #'eglot-ensure)
(add-hook 'nix-mode-hook #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)
(add-hook 'rust-ts-mode-hook #'eglot-ensure)
(add-hook 'zig-mode-hook #'eglot-ensure)


(defun setup-term ()
  "Common terminal setup"
  ;; TODO(jared): this seems to cause problems
  ;; ;; line numbers are not nearly useful in terminal like environments
  ;; (with-editor-export-editor)
  (line-number-mode -1)
  (display-line-numbers-mode -1))

(add-hook 'nix-repl-hook #'setup-term)
(add-hook 'shell-mode-hook #'setup-term)
(add-hook 'term-mode-hook #'setup-term)
(add-hook 'shell-command-mode-hook #'view-mode) ;; ensure we can't modify buffer for shell output
(add-hook 'eat-mode-hook #'setup-term)
(add-hook 'eshell-load-hook #'setup-term)
(add-hook 'eshell-load-hook #'eat-eshell-mode)

(if (eq system-type 'darwin)
    (add-hook 'vterm-mode-hook #'setup-term)
  (progn
    (add-hook 'ghostel-mode-hook #'setup-term)
    (add-hook 'ghostel-mode-hook #'evil-ghostel-mode)))

;; Ensure we load custom-file, if set
(unless (eq custom-file nil)
  (when (file-exists-p custom-file)
    (load custom-file)))
