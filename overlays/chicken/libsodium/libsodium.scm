(module libsodium
	(crypto-sign-bytes
	  crypto-sign-detached
	  crypto-sign-verify-detached)

	(import
	  (scheme base)
	  (chicken foreign))

	(foreign-declare "#include <sodium.h>")

	(define crypto-sign-bytes (foreign-value "crypto_sign_BYTES" size_t))
	(define crypto-sign-detached
	  (foreign-lambda int crypto_sign_detached
			  nonnull-bytevector
			  (c-pointer "unsigned long long")
			  (const bytevector)
			  unsigned-integer64
			  (const nonnull-bytevector)))
	(define crypto-sign-verify-detached
	  (foreign-lambda int crypto_sign_verify_detached
			  (const nonnull-bytevector)
			  (const bytevector)
			  unsigned-integer64
			  (const nonnull-bytevector)))

	(when (< ((foreign-lambda int sodium_init)) 0)
	  (error "sodium_init failed")))
