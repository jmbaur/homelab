;; basics
(load-theme 'modus-vivendi)
(global-display-line-numbers-mode 1)
(menu-bar-mode -1)
(toggle-truncate-lines 1)
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

;; completion
(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode 1)

;; project integration
(projectile-mode 1)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

;; direnv
(envrc-global-mode 1)
