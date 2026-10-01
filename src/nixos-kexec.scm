#>
#include <linux/kexec.h>
#include <sys/syscall.h>
#include <signal.h>

<#

(import
  srfi-13
  (chicken file posix)
  (chicken file)
  (chicken foreign)
  (chicken format)
  (chicken io)
  (chicken process signal)
  (chicken process)
  (chicken sort)
  (chicken string)
  (scheme process-context))

(define (system-profile-entries)
  (map cdr (sort
	     (foldl (lambda (acc path) (if (symbolic-link? path)
					 (cons (cons (file-change-time path) path) acc)
					 acc))
		    '()
		    (glob "/nix/var/nix/profiles/system-*-link"))
	     (lambda (a b) (> (car a) (car b))))))

(define kexec-file-load
  (foreign-lambda* int ((int kernel) (int initrd) (c-string cmdline) (int cmdline_len))
		   "C_return(syscall(SYS_kexec_file_load, kernel, initrd, cmdline_len, cmdline, 0));"))

(define (extract-toplevel path)
  (list
    (cons 'kernel (conc path "/kernel"))
    (cons 'initrd (conc path "/initrd"))
    (cons 'cmdline (conc (conc (conc "init=" (read-symbolic-link path #t)) "/init ")
			 (call-with-input-file
			   (conc path "/kernel-params")
			   (lambda (port) (read-string #f port)))))))

(let* ((args (command-line))
       (chosen (if (> (length args) 1)
		 (car (reverse args))
		 (begin
		   (printf "Found the following NixOS generations:\n~a\nwhich one would you like to kexec? "
			   (string-intersperse (system-profile-entries) "\n"))
		   (read-line))))
       (kexec-signal (+ 6 (foreign-value "SIGRTMIN" int))) ;; from systemd(1) manpage
       (toplevel (extract-toplevel chosen))
       (kernel (file-open (alist-ref 'kernel toplevel) open/rdonly))
       (initrd (file-open (alist-ref 'initrd toplevel) open/rdonly))
       (cmdline (alist-ref 'cmdline toplevel))
       (ret (kexec-file-load kernel initrd cmdline (+ 1 (string-length cmdline)))))
  (if (< ret 0)
    (printf "failed to kexec_file_load(): ~a\n" ret)
    (process-signal 1 kexec-signal)))
