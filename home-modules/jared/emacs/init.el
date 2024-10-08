;; basics
(load-theme 'modus-vivendi)
(global-display-line-numbers-mode 1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(set-default 'truncate-lines t)
(global-set-key "\C-h" 'delete-backward-char)
(global-set-key "\C-xh" 'help-command) ;; overrides mark-whole-buffer
(setq ring-bell-function 'ignore)
(setq initial-buffer-choice t)

;; tramp
(require 'tramp)
(add-to-list 'tramp-remote-path 'tramp-own-remote-path)

;; auto-reload dired when there are filesystem changes
(add-hook 'dired-mode-hook 'auto-revert-mode)

;; evil
(setq evil-want-C-u-scroll t)
(setq evil-want-integration t)
(setq evil-want-keybinding nil)
(evil-mode 1)
(evil-collection-init)
(evil-commentary-mode 1)
(global-evil-surround-mode 1)
(global-evil-collection-unimpaired-mode 1)
(evil-set-undo-system 'undo-redo)
(define-key evil-normal-state-map (kbd "C-c +") 'evil-numbers/inc-at-pt)
(define-key evil-visual-state-map (kbd "C-c +") 'evil-numbers/inc-at-pt)
(define-key evil-normal-state-map (kbd "C-c -") 'evil-numbers/dec-at-pt)
(define-key evil-visual-state-map (kbd "C-c -") 'evil-numbers/dec-at-pt)

;; completion (requires orderless and vertico)
(setq completion-styles '(orderless basic)
      completion-category-overrides '((file (styles basic partial-completion))))
(vertico-mode 1)

;; project integration (requires projectile)
(projectile-mode 1)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

;; direnv
(envrc-global-mode 1)

;; completions
(add-hook 'after-init-hook 'global-company-mode)

(setq eldoc-echo-area-use-multiline-p nil)

(setq eglot-workspace-configuration
      '(:nil (:formatting (:command ["nixfmt"]))))

(defun lsp-setup ()
  (add-hook 'before-save-hook 'eglot-format-buffer nil t)
  (eglot-ensure))

(add-hook 'go-mode-hook 'lsp-setup)
(add-hook 'nix-mode-hook 'lsp-setup)
(add-hook 'python-mode-hook 'lsp-setup)
(add-hook 'rust-mode-hook 'lsp-setup)
(add-hook 'zig-mode-hook 'lsp-setup)
