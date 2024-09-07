;; basics
(load-theme 'modus-vivendi)
(global-display-line-numbers-mode 1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(set-default 'truncate-lines t)
(global-set-key "\C-h" 'delete-backward-char)
(global-set-key "\C-xh" 'help-command) ;; overrides mark-whole-buffer

;; clipboard
(global-clipetty-mode 1)

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

;; lsp
(setq eldoc-echo-area-use-multiline-p nil)
(add-hook 'go-mode-hook 'eglot-ensure)
(add-hook 'nix-mode-hook 'eglot-ensure)
(add-hook 'rust-mode-hook 'eglot-ensure)
(add-hook 'zig-mode-hook 'eglot-ensure)
