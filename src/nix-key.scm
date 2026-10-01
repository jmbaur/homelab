(import
  base64
  libsodium
  srfi-1
  (chicken bytevector)
  (chicken io)
  (chicken port)
  (chicken process-context)
  (chicken string))

(define (decode-key decoded . keys)
  (if (= 0 (length keys))
    decoded
    (apply decode-key (cons 
			(let* ((key (string-split (car keys) ":"))
			       (key-name (car key))
			       (key-value (string->latin1 (base64-decode (cadr key)))))
			  (cons key-name key-value))
			decoded) (cdr keys))))

(define (sign data-filepath key-filepath)
  (let* ((data (call-with-input-file data-filepath (lambda (port)
						     (read-bytevector #f port))))
	 (key (car (decode-key '() (call-with-input-file key-filepath (lambda (port)
									(read-string #f port))))))
	 (sig (make-bytevector crypto-sign-bytes))
	 (ret (crypto-sign-detached sig #f data (bytevector-length data) (cdr key))))
    (if (not (= ret 0))
      (error "sign failed")
      (write-line (string-append (car key) ":" (base64-encode (latin1->string sig)))))))

(define (verify data-filepath signature-filepath . public-keys)
  (let* ((data (call-with-input-file data-filepath (lambda (port)
						     (read-bytevector #f port))))
	 (signature (car (decode-key '() (call-with-input-file signature-filepath (lambda (port)
										    (read-string #f port))))))
	 (verify-keys (apply decode-key '() public-keys))
	 (verify-key (alist-ref (car signature) verify-keys equal?))
	 (ret (crypto-sign-verify-detached
		(cdr signature)
		data
		(bytevector-length data)
		(if (not verify-key)
		  (error "missing verification key")
		  verify-key))))
    (exit (if (= ret 0) ret 1))))

(define (choose-action args)
  (apply (eval (string->symbol (car args)) (interaction-environment)) (cdr args)))

(choose-action (command-line-arguments))
