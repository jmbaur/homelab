(module qrencode
	(ec-level-l
	  ec-level-m
	  ec-level-q
	  ec-level-h
	  mode-8
	  mode-kanji
	  qrcode?
	  qrcode-version
	  qrcode-width
	  qrcode-data
	  qrcode-dark?
	  qrcode-encode-string
	  qrcode-encode-string-8bit
	  qrcode-encode-data)

	(import
	  (scheme base)
	  (chicken base)
	  (chicken foreign))

	(foreign-declare "#include <errno.h>\n#include <string.h>\n#include <qrencode.h>")

	(define ec-level-l (foreign-value "QR_ECLEVEL_L" int))
	(define ec-level-m (foreign-value "QR_ECLEVEL_M" int))
	(define ec-level-q (foreign-value "QR_ECLEVEL_Q" int))
	(define ec-level-h (foreign-value "QR_ECLEVEL_H" int))

	;; The only modes QRcode_encodeString accepts as a hint.
	(define mode-8 (foreign-value "QR_MODE_8" int))
	(define mode-kanji (foreign-value "QR_MODE_KANJI" int))

	;; data holds width*width modules, row-major; see qrencode.h for the bit layout.
	(define-record-type qrcode
	  (make-qrcode version width data)
	  qrcode?
	  (version qrcode-version)
	  (width qrcode-width)
	  (data qrcode-data))

	(define (qrcode-dark? qr x y)
	  (odd? (bytevector-u8-ref (qrcode-data qr) (+ x (* y (qrcode-width qr))))))

	(define-foreign-type qrcode* (c-pointer "QRcode"))

	(define qrcode*-version (foreign-lambda* int ((qrcode* q)) "C_return(q->version);"))
	(define qrcode*-width (foreign-lambda* int ((qrcode* q)) "C_return(q->width);"))
	(define qrcode*-copy-data!
	  (foreign-lambda* void ((qrcode* q) (nonnull-bytevector dst))
			   "memcpy(dst, q->data, q->width * q->width);"))
	(define qrcode*-free (foreign-lambda void QRcode_free qrcode*))

	(define get-errno (foreign-lambda* int () "C_return(errno);"))
	(define strerror (foreign-lambda c-string "strerror" int))

	;; Copy into the Scheme heap and free right away so callers never manage C memory.
	(define (qrcode*->qrcode who q)
	  (unless q
	    (error who (strerror (get-errno))))
	  (let* ((width (qrcode*-width q))
		 (data (make-bytevector (* width width))))
	    (qrcode*-copy-data! q data)
	    (let ((qr (make-qrcode (qrcode*-version q) width data)))
	      (qrcode*-free q)
	      qr)))

	;; version 0 picks the smallest version that fits.
	(define (qrcode-encode-string s #!key (version 0) (level ec-level-l) (hint mode-8) (case-sensitive #t))
	  (qrcode*->qrcode
	    'qrcode-encode-string
	    ((foreign-lambda qrcode* QRcode_encodeString nonnull-c-string int int int bool)
	     s version level hint case-sensitive)))

	(define (qrcode-encode-string-8bit s #!key (version 0) (level ec-level-l))
	  (qrcode*->qrcode
	    'qrcode-encode-string-8bit
	    ((foreign-lambda qrcode* QRcode_encodeString8bit nonnull-c-string int int)
	     s version level)))

	(define (qrcode-encode-data bv #!key (version 0) (level ec-level-l))
	  (qrcode*->qrcode
	    'qrcode-encode-data
	    ((foreign-lambda qrcode* QRcode_encodeData int (const nonnull-bytevector) int int)
	     (bytevector-length bv) bv version level))))
