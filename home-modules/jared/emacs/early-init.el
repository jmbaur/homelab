;; This defaults to XDG_CONFIG_HOME, which is bad because lots of
;; state gets written to it.
(setq user-emacs-directory
      (concat (file-name-as-directory
	       (let ((xdg-data-home (getenv "XDG_DATA_HOME")))
		 (if (not (equal nil xdg-data-home))
		     xdg-data-home
		   (concat (file-name-as-directory (getenv "HOME")) ".local/share")))) "emacs"))
