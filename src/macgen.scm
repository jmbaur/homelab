(import
  srfi-1
  (chicken bitwise)
  (chicken bytevector)
  (chicken io)
  (chicken random)
  (chicken string))

(define (hex-octet n)
  (string-append (if (< n 16) "0" "") (number->string n 16)))

(define (macgen)
  (let* ((locally-administered-bit #b10)
	 (unicast-mask #xfe)
	 (bytes (random-bytes (make-bytevector 6))))
    (bytevector-u8-set! bytes 0 (bitwise-and (bitwise-ior (bytevector-u8-ref bytes 0)
							  locally-administered-bit)
					     unicast-mask))
    (string-intersperse
      (map (lambda (i) (hex-octet (bytevector-u8-ref bytes i))) (iota 6)) ":")))

(write-line (macgen))
