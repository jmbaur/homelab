;; This defaults to XDG_CONFIG_HOME, which is bad because lots of
;; state gets written to it.
(setq user-emacs-directory
      (concat (file-name-as-directory
	       (or (getenv "XDG_DATA_HOME")
		   (concat (file-name-as-directory (getenv "HOME")) ".local/share"))) "emacs"))
