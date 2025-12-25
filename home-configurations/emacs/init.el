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
(fido-vertical-mode 1)
(rg-enable-default-bindings)

(if (and window-system (fboundp 'scroll-bar-mode))
    (scroll-bar-mode -1)
  (setq interprogram-cut-function 'osc52-select-text))

(load-theme 'modus-vivendi)

(setq direnv-always-show-summary nil)
(direnv-mode 1)

(evil-mode 1)
(global-evil-surround-mode 1)
(evil-commentary-mode 1)
(evil-collection-init)

;; scrape the projects directory, if it has not yet been scraped
(let ((project-file (file-name-concat xdg-cache-home "emacs" "projects"))
      (projects-dir (file-name-concat xdg-state-home "projects")))
  (setq project-list-file project-file)
  (unless (file-exists-p project-file)
    (project-remember-projects-under projects-dir)))

(defun setup-lsp (&optional format-on-save)
  "LSP common setup"
  (define-key eglot-mode-map (kbd "C-c e f n") #'flymake-goto-next-error)
  (define-key eglot-mode-map (kbd "C-c e f p") #'flymake-goto-prev-error)
  (define-key eglot-mode-map (kbd "C-c e r") #'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c C-o") #'company-complete)
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
			   (zig-format-on-save-mode -1) ; we use eglot-format instead
			   (setup-lsp)))
(add-hook 'vterm-mode-hook (lambda ()
			     (display-line-numbers-mode -1)))
(add-hook 'eat-mode-hook (lambda ()
			   (display-line-numbers-mode -1)))
(add-hook 'eshell-load-hook (lambda ()
			      (display-line-numbers-mode -1)
			      (eat-eshell-mode)))

;; ensure we load custom-file, if set
(unless (eq custom-file nil)
  (when (file-exists-p custom-file)
    (load custom-file)))
