;;; -*- lexical-binding: t -*-

(require 'company)
(require 'direnv)
(require 'eat)
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

(if (and window-system (fboundp 'scroll-bar-mode))
    (scroll-bar-mode -1)
  (setq interprogram-cut-function 'osc52-select-text))

(setq mode-line-compact 'long)

(load-theme 'modus-vivendi)

(setq direnv-always-show-summary nil)
(direnv-mode 1)

(global-sops-mode 1)

(evil-set-undo-system 'undo-redo)
(setq evil-want-Y-yank-to-eol t)
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
  (project-remember-projects-under (file-name-concat xdg-state-home "projects")))

;; scrape the projects directory, if it has not yet been scraped
(unless (file-exists-p project-list-file)
  (refresh-projects))

(defun eat-project-new ()
  "Start a new Eat session in the current project's root directory"
  (interactive)
  (eat-project t))

;; add extra keybindings for project switching
(define-key project-prefix-map "t" 'eat-project-new)
(define-key project-prefix-map "r" 'rg-project) ;; overrides project-query-replace-regexp
(define-key project-prefix-map "m" 'magit-project-status)

;; ensure the extra commands show up when switching projects
(add-to-list 'project-switch-commands '(project-execute-extended-command "Extended command") t)
(add-to-list 'project-switch-commands '(eat-project-new "Eat") t)
(add-to-list 'project-switch-commands '(rg-project "Find ripgrep") t)
(add-to-list 'project-switch-commands '(magit-project-status "Magit") t)

(defun setup-lsp (&optional format-on-save)
  "LSP common setup"
  (interactive)
  (define-key eglot-mode-map (kbd "C-c e f n") #'flymake-goto-next-error)
  (define-key eglot-mode-map (kbd "C-c e f p") #'flymake-goto-prev-error)
  (define-key eglot-mode-map (kbd "C-c e r") #'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c C-o") #'company-complete) ;; TODO(jared): we want this enabled for all company-enabled buffers
  (setq company-idle-delay nil)
  (company-mode)
  (eglot-ensure)
  (if (or format-on-save t)
      (add-hook 'after-save-hook 'eglot-format nil t)))

(add-hook 'bash-ts-mode 'setup-lsp)
(add-hook 'c-mode-hook 'setup-lsp)
(add-hook 'nix-mode-hook 'setup-lsp)
(add-hook 'rust-mode-hook 'setup-lsp)
(add-hook 'zig-mode-hook (lambda ()
			   (zig-format-on-save-mode -1) ;; we use eglot-format instead
			   (setup-lsp)))

(defun setup-term ()
  ;; line numbers are not nearly useful in terminal like environments
  (line-number-mode -1)
  (display-line-numbers-mode -1))

(add-hook 'eat-mode-hook 'setup-term)
(add-hook 'nix-repl-hook 'setup-term)
(add-hook 'shell-mode-hook 'setup-term)
(add-hook 'term-mode-hook 'setup-term)
(add-hook 'vterm-mode-hook 'setup-term)
(add-hook 'shell-command-mode-hook 'view-mode) ;; ensure we can't modify buffer for shell output
(add-hook 'eshell-load-hook (lambda ()
			      (setup-term)
			      (eat-eshell-mode)))

;; ensure we load custom-file, if set
(unless (eq custom-file nil)
  (when (file-exists-p custom-file)
    (load custom-file)))
