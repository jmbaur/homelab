;; basics
(load-theme 'modus-operandi)
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
(evil-surround-mode 1)
(evil-set-undo-system 'undo-redo)

;; completion
(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode 1)

;; project integration
(projectile-mode 1)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

;; direnv
(envrc-global-mode 1)

;; completions
(add-hook 'after-init-hook 'global-company-mode)

(setq eldoc-echo-area-use-multiline-p nil)

(setq eglot-workspace-configuration
      '(:nil (:formatting (:command ["nixfmt"]))))

(defun nix-setup ()
  (add-hook 'before-save-hook 'eglot-format-buffer nil t)
  (eglot-ensure))
(add-hook 'nix-mode-hook 'nix-setup)

(defun zig-setup ()
  (add-hook 'before-save-hook 'eglot-format-buffer nil t)
  (eglot-ensure))
(add-hook 'zig-mode-hook 'zig-setup)

(add-hook 'go-mode-hook 'eglot-ensure)
(add-hook 'rust-mode-hook 'eglot-ensure)
