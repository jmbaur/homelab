(module gpiocdev
	(line-flag-input
	  line-flag-output
	  line-flag-active-low
	  gpio-request-lines
	  gpio-release-lines
	  gpio-get-values
	  gpio-set-values!)

	(import
	  (scheme base)
	  (chicken base)
	  (chicken foreign)
	  (chicken file posix))

	(foreign-declare "#include <errno.h>\n#include <string.h>\n#include <sys/ioctl.h>\n#include <linux/gpio.h>")

	(define line-flag-input (foreign-value "GPIO_V2_LINE_FLAG_INPUT" unsigned-integer64))
	(define line-flag-output (foreign-value "GPIO_V2_LINE_FLAG_OUTPUT" unsigned-integer64))
	(define line-flag-active-low (foreign-value "GPIO_V2_LINE_FLAG_ACTIVE_LOW" unsigned-integer64))

	(define lines-max (foreign-value "GPIO_V2_LINES_MAX" int))

	;; Returns -errno on failure so the caller sees the ioctl's errno, not a later one.
	(define ioctl*
	  (foreign-lambda* int ((int fd) (unsigned-long req) (scheme-pointer arg))
			   "C_return(ioctl(fd, req, arg) < 0 ? -errno : 0);"))

	(define strerror (foreign-lambda c-string "strerror" int))

	(define (check-ioctl who fd req arg)
	  (let ((ret (ioctl* fd req arg)))
	    (when (< ret 0)
	      (error who (strerror (- ret))))))

	(define-foreign-type line-request
	  (nonnull-scheme-pointer "struct gpio_v2_line_request"))

	(define line-request-size (foreign-type-size "struct gpio_v2_line_request"))

	(define line-request-offset-set!
	  (foreign-lambda* void ((line-request r) (int i) (unsigned-integer32 offset))
			   "r->offsets[i] = offset;"))
	(define line-request-num-lines-set!
	  (foreign-lambda* void ((line-request r) (unsigned-integer32 n)) "r->num_lines = n;"))
	(define line-request-flags-set!
	  (foreign-lambda* void ((line-request r) (unsigned-integer64 flags)) "r->config.flags = flags;"))
	(define line-request-consumer-set!
	  (foreign-lambda* void ((line-request r) (c-string s))
			   "strncpy(r->consumer, s, sizeof(r->consumer) - 1);"))
	(define line-request-fd
	  (foreign-lambda* int ((line-request r)) "C_return(r->fd);"))

	(define-foreign-type line-values
	  (nonnull-scheme-pointer "struct gpio_v2_line_values"))

	(define line-values-size (foreign-type-size "struct gpio_v2_line_values"))

	(define line-values-bits
	  (foreign-lambda* unsigned-integer64 ((line-values v)) "C_return(v->bits);"))
	(define line-values-bits-set!
	  (foreign-lambda* void ((line-values v) (unsigned-integer64 x)) "v->bits = x;"))
	(define line-values-mask-set!
	  (foreign-lambda* void ((line-values v) (unsigned-integer64 x)) "v->mask = x;"))

	(define (make-line-values bits mask)
	  (let ((v (make-bytevector line-values-size 0)))
	    (line-values-bits-set! v bits)
	    (line-values-mask-set! v mask)
	    v))

	(define (all-lines-mask n)
	  (- (expt 2 n) 1))

	;; Returns the line fd. Bit i in values/masks refers to (list-ref offsets i).
	(define (gpio-request-lines chip offsets #!key (flags line-flag-output) (consumer "chicken"))
	  (let ((n (length offsets)))
	    (unless (<= 1 n lines-max)
	      (error 'gpio-request-lines "bad number of lines" n))
	    (let ((r (make-bytevector line-request-size 0))
		  (chip-fd (file-open chip open/rdonly)))
	      (let loop ((i 0) (offsets offsets))
		(unless (null? offsets)
		  (line-request-offset-set! r i (car offsets))
		  (loop (+ i 1) (cdr offsets))))
	      (line-request-num-lines-set! r n)
	      (line-request-flags-set! r flags)
	      (line-request-consumer-set! r consumer)
	      (dynamic-wind
		void
		(lambda ()
		  (check-ioctl 'gpio-request-lines chip-fd
			       (foreign-value "GPIO_V2_GET_LINE_IOCTL" unsigned-long) r))
		(lambda () (file-close chip-fd)))
	      (line-request-fd r))))

	(define (gpio-release-lines fd)
	  (file-close fd))

	(define (gpio-get-values fd #!optional (mask (all-lines-mask lines-max)))
	  (let ((v (make-line-values 0 mask)))
	    (check-ioctl 'gpio-get-values fd
			 (foreign-value "GPIO_V2_LINE_GET_VALUES_IOCTL" unsigned-long) v)
	    (line-values-bits v)))

	(define (gpio-set-values! fd bits #!optional (mask (all-lines-mask lines-max)))
	  (check-ioctl 'gpio-set-values! fd
		       (foreign-value "GPIO_V2_LINE_SET_VALUES_IOCTL" unsigned-long)
		       (make-line-values bits mask))))
