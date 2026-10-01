(import
  srfi-1
  srfi-13
  srfi-180
  (scheme base)
  (chicken bitwise)
  (chicken io)
  (chicken format)
  (chicken string))

(define (chunk-prefix z lst)
  (if (= 0 (length lst)) z
    (chunk-prefix
      (append z (list (let* ((next (take lst 2)))
			(bitwise-ior
			  (arithmetic-shift (car next) 8)
			  (cadr next)))))
      (drop lst 2))))

(let* ((input (json-read (current-input-port)))
       (prefixes (vector->list (alist-ref 'Prefixes (alist-ref 'DHCPv6Client input)))))
  (for-each (lambda (prefix)
	      (printf "~a/~a\n"
		      (string-intersperse
			(map (lambda (x)
			       (string-pad (number->string x 16) 4 #\0))
			     (chunk-prefix '() (vector->list (alist-ref 'Prefix prefix))))
			":")
		      (alist-ref 'PrefixLength prefix)))
	    prefixes))
