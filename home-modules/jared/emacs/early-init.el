;; This defaults to XDG_CONFIG_HOME, which is bad because lots of
;; state gets written to it.
(setq user-emacs-directory
      (concat (file-name-as-directory (getenv "XDG_DATA_HOME")) "emacs"))
