(import
  http-client
  intarweb
  openssl ; http-client only picks up HTTPS support if openssl is already loadable.
  qrencode
  srfi-180
  uri-common
  (chicken format)
  (chicken io)
  (chicken port)
  (chicken string)
  (scheme base))

(define margin 2)
(define empty " ")
(define lower "\x2584;")
(define upper "\x2580;")
(define full "\x2588;")

(define (write-utf8-margin margin width)
  (do ((y 0 (+ 1 y)))
    ((>= y (quotient margin 2)))
    (do ((x 0 (+ 1 x)))
      ((>= x width))
      (display full))
    (newline)))

(define (write-utf8-row-margin margin)
  (do ((x 0 (+ 1 x)))
    ((>= x margin))
    (display full)))

(define (write-utf8 qrcode)
  (let* ((width (qrcode-width qrcode))
	 (real-width (+ width (* 2 margin))))
    (write-utf8-margin margin real-width)
    (do ((y 0 (+ 2 y)))
      ((>= y width))
      (write-utf8-row-margin margin)
      (do ((x 0 (+ 1 x)))
	((>= x width))
	(let ((top (qrcode-dark? qrcode x y))
	      (bottom (and (< (+ 1 y) width) (qrcode-dark? qrcode x (+ 1 y)))))
	  (display (cond ((and top bottom) empty)
			 (top lower)
			 (bottom upper)
			 (else full)))))
      (write-utf8-row-margin margin)
      (newline))
    (write-utf8-margin margin real-width)))

(let* ((uri-raw "https://paste.jmbaur.com")
       (uri (uri-reference uri-raw))
       (post-data (with-output-to-string
		    (lambda ()
		      (json-write `((text . ,(read-string #f (current-input-port))))
				  (current-output-port)))))
       (req (make-request method: 'POST
			  uri: uri
			  headers: (headers '((content-type application/json)))))
       (path (alist-ref 'path (with-input-from-request req post-data json-read)))
       (upload-url (conc uri-raw "/raw" path))
       (qrcode (qrcode-encode-string-8bit upload-url)))
  (write-line upload-url)
  (write-utf8 qrcode))
