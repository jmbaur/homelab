(import
  gpiocdev
  intarweb
  simple-logger
  spiffy
  srfi-18
  uri-common
  (scheme base)
  (chicken base)
  (chicken io)
  (chicken process-context)
  (chicken tcp))

(import-for-syntax (chicken io))

(define-syntax embed-file
  (er-macro-transformer
    (lambda (x r c)
      (call-with-input-file (cadr x) (lambda (port) (read-string #f port))))))

(define index-html (string->utf8 (embed-file "garage-door.html")))

(log-level 10) ; debug

;; Overlapping requests would interleave the relay pulses.
(define toggle-mutex (make-mutex 'toggle))

(define (toggle fd)
  (mutex-lock! toggle-mutex)
  (log-debug "setting set pin high")
  (gpio-set-values! fd #b01)
  (thread-sleep! 1)
  (log-debug "setting unset pin high")
  (gpio-set-values! fd #b10)
  (thread-sleep! 1)
  (log-debug "setting both pins low")
  (gpio-set-values! fd #b00)
  (mutex-unlock! toggle-mutex))

;; (chicken tcp) can't adopt an fd, but tcp-accept only needs it in slot 1.
(define (socket-activated-listener fd)
  (##sys#make-structure 'tcp-listener fd))

;; spiffy's send-response sets Content-Length from string-length, which counts
;; characters, not bytes.
(define (send-bytes body content-type)
  (with-headers `((content-type ,content-type)
		  (content-length ,(bytevector-length body)))
    (lambda ()
      (write-logged-response)
      (let ((response (current-response)))
	(unless (eq? 'HEAD (request-method (current-request)))
	  (write-string (utf8->string body) (response-port response)))
	(finish-response-body response)))))

(define (handler line-fd)
  (lambda (continue)
    (let ((path (uri-path (request-uri (current-request)))))
      (cond
	((equal? path '(/ ""))
	 (send-bytes index-html #(text/html ((charset . utf-8)))))
	((equal? path '(/ "toggle"))
	 ;; The client gets its response before the relay sequence starts.
	 (send-bytes (string->utf8 "OK") 'text/plain)
	 (toggle line-fd))
	(else (continue))))))

(define (parse-line s)
  (or (and s (string->number s))
      (error "usage: homelab-garage-door CHIP SET-LINE UNSET-LINE")))

(let* ((args (command-line-arguments))
       (chip (if (pair? args) (car args) (parse-line #f)))
       ;; assumes latching relay
       (set-line (parse-line (and (>= (length args) 2) (list-ref args 1))))
       (unset-line (parse-line (and (>= (length args) 3) (list-ref args 2))))
       (line-fd (begin
		  (log-info "using ~a, set line ~a and unset line ~a" chip set-line unset-line)
		  (gpio-request-lines chip (list set-line unset-line) consumer: "garage-door"))))
  (if (get-environment-variable "LISTEN_FDS")
    (parameterize ((vhost-map `((".*" . ,(handler line-fd)))))
      (accept-loop (socket-activated-listener 3) tcp-accept))
    (toggle line-fd))
  (gpio-release-lines line-fd))
