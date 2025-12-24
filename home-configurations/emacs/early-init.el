;;; -*- lexical-binding: t -*-

(setq-default truncate-lines t)

(setq load-prefer-newer t)
(setq native-comp-jit-compilation t)
(setq evil-want-C-u-scroll t)
(setq evil-want-keybinding nil)
(setq inhibit-splash-screen t)
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
