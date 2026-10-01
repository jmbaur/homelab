(import
  simple-logger
  srfi-18
  (scheme base)
  (chicken base)
  (chicken condition)
  (chicken file)
  (chicken file posix)
  (chicken foreign)
  (chicken format)
  (chicken io)
  (chicken pathname)
  (chicken process)
  (chicken process-context)
  (chicken string)
  (chicken tcp))

(foreign-declare "#include \"homelab-backup-recv.h\"")

(log-level 20) ; info

(define (usage)
  (fprintf (current-error-port) "usage:\n~a: <peer-file> <snapshot-root> <port>\n" (program-name))
  (exit 1))

(define canonical-ip6 (foreign-lambda c-string "canonical_ip6" c-string))

;; Peers are identified by source address, which tcp-addresses only gets right
;; for AF_INET.
(define peer-ip6 (foreign-lambda c-string "peer_ip6" int))

;; tcp-listen only binds AF_INET.
(define listen6 (foreign-lambda int "listen6" int))

;; Keeps other peers' connections out of btrfs children, which would otherwise
;; hold them open until they exit.
(define set-cloexec!
  (foreign-lambda* void ((int fd)) "fcntl(fd, F_SETFD, FD_CLOEXEC);"))

(define strerror (foreign-lambda c-string "strerror" int))

;; (chicken tcp) can't adopt an fd, but tcp-accept only needs it in slot 1.
(define (fd->tcp-listener fd)
  (##sys#make-structure 'tcp-listener fd))

;; Returns an alist of canonical IPv6 address to peer name.
(define (parse-peers port)
  (let loop ((peers '()))
    (let ((line (read-line port)))
      (cond
	((eof-object? line) (reverse peers))
	((string=? line "") (loop peers))
	(else
	  (let* ((fields (string-split line " "))
		 (ip (and (>= (length fields) 2) (canonical-ip6 (cadr fields)))))
	    (if ip
	      (loop (cons (cons ip (car fields)) peers))
	      (begin
		(log-error "invalid line '~a'" line)
		(loop peers)))))))))

(define (format-bytes n)
  (let loop ((n n) (units '("B" "KiB" "MiB" "GiB" "TiB" "PiB")))
    (if (or (< n 1024) (null? (cdr units)))
      (conc (/ (round (* n 100)) 100) (car units))
      (loop (/ n 1024.) (cdr units)))))

;; Returns the number of bytes copied.
(define (copy-bytes in out)
  (let loop ((total 0))
    (let ((buf (read-bytevector 65536 in)))
      (if (eof-object? buf)
	total
	(begin
	  (write-bytevector buf out)
	  (loop (+ total (bytevector-length buf))))))))

(define (receive-backup in peer-name snapshot-root)
  (let ((snapshot-path (make-pathname snapshot-root peer-name)))
    (create-directory snapshot-path #t)
    (let* ((child (process "btrfs" (list "receive" "-e" snapshot-path)))
	   (child-in (process-input-port child))
	   (child-out (process-output-port child))
	   ;; Drained concurrently so a chatty btrfs can't fill the pipe and stall.
	   (stdout-copier (thread-start!
			    (lambda () (copy-bytes child-out (current-output-port)))))
	   (total (dynamic-wind
		    void
		    (lambda ()
		      (let ((total (copy-bytes in child-in)))
			;; btrfs-receive requires writing an EOF byte
			(write-bytevector (bytevector 0) child-in)
			total))
		    (lambda () (close-output-port child-in)))))
      (thread-join! stdout-copier)
      ;; Closing the last port reaps the child.
      (close-input-port child-out)
      (if (and (process-returned-normally? child) (zero? (process-exit-status child)))
	(log-info "finished backup for peer ~a (received ~a)" peer-name (format-bytes total))
	(log-error "failed to backup peer ~a (btrfs exited with status ~a)"
		   peer-name
		   (process-exit-status child))))))

(define (handle-connection in peers snapshot-root)
  (let* ((address (peer-ip6 (port->fileno in)))
	 (peer-name (and address (alist-ref address peers equal?))))
    (if peer-name
      (receive-backup in peer-name snapshot-root)
      (log-warning "address ~a not found in peers" address))))

(define (serve listener peers snapshot-root)
  (let loop ()
    (receive (in out) (tcp-accept listener)
	     (set-cloexec! (port->fileno in))
	     (thread-start!
	       (lambda ()
		 (handle-exceptions e
				    (log-error "failed to handle connection: ~a ~s"
					       (get-condition-property e 'exn 'message "unknown error")
					       (get-condition-property e 'exn 'arguments '()))
				    (dynamic-wind
				      void
				      (lambda () (handle-connection in peers snapshot-root))
				      (lambda ()
					(close-input-port in)
					(close-output-port out)))))))
    (loop)))

(let* ((args (command-line-arguments))
       (port (and (= 3 (length args)) (string->number (list-ref args 2)))))
  (unless (and port (exact-integer? port) (<= 0 port 65535))
    (usage))
  (let ((peers (call-with-input-file (car args) parse-peers))
	(snapshot-root (cadr args))
	(fd (listen6 port)))
    (for-each (lambda (peer)
		(log-info "using peer '~a' at ~a" (cdr peer) (car peer)))
	      peers)
    (when (< fd 0)
      (error "failed to listen" port (strerror (- fd))))
    ;; Backups can sit idle while btrfs-send walks large files.
    (parameterize ((tcp-read-timeout #f))
      (serve (fd->tcp-listener fd) peers snapshot-root))))
