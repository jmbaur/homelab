#>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

<#

(import
  dbus
  json
  srfi-1
  srfi-18
  tcprepl
  (chicken condition)
  (chicken format)
  (chicken port)
  (chicken process-context)
  (chicken process-context posix)
  (only (chicken tcp) tcp-accept tcp-read-timeout)
  (chicken time)
  (chicken time posix))

;; A sway status bar. It speaks sway's json protocol on stdout and reads
;; system state over the system bus.
;;
;; The program is meant to be driven from a repl: tcprepl over the unix
;; socket $SWAYBAR_REPL_SOCK or $XDG_RUNTIME_DIR/swaybar-repl.sock; setting
;; SWAYBAR_REPL_SOCK to 0 turns it off. Block handlers are looked up by name
;; on every tick, so redefining
;; one over the connection -- C-M-x on the battery-percentage definition in
;; emacs, say -- is what makes the bar pick up a new implementation.
;; Everything the bar holds is a top-level global to edit:
;;
;;   swaybar-blocks      list of block records
;;   swaybar-interval    seconds between ticks
;;   (swaybar-block 'x)  find a block by name
;;   swaybar-refresh!    force every block to re-read on the next tick
;;   swaybar-log         tab-separated log line to stderr
;;
;; A block with a path is driven by dbus: the bar subscribes to signals from
;; that object and only calls its handler again when one arrives. A block
;; without one (the clock) is called every interval seconds.

;; --- blocks ---------------------------------------------------------------

(define-record-type block
  (block-make name handler path dirty json rendered-handler rendered-path last-error)
  block?
  (name block-name)
  (handler block-handler set-block-handler!)
  (path block-path set-block-path!)
  (dirty block-dirty set-block-dirty!)
  (json block-json set-block-json!)
  (rendered-handler block-rendered-handler set-block-rendered-handler!)
  (rendered-path block-rendered-path set-block-rendered-path!)
  (last-error block-last-error set-block-last-error!))

(define (make-block name handler #!key path)
  (block-make name handler
	      (and path (if (symbol? path) (symbol->string path) path))
	      #t #f #f #f #f))

;; swaybar-blocks is a plain list to edit from the repl:
;;
;;   (set! swaybar-blocks
;;         (append swaybar-blocks (list (make-block 'load 'load-average))))
;;
;; Match rules follow whatever paths the blocks declare on the next tick, so
;; a block can be added, removed or repointed at another object this way.
(define swaybar-interval 1)

(define swaybar-blocks
  (list
    (make-block 'battery 'battery-percentage
		path: "/org/freedesktop/UPower/devices/DisplayDevice")
    (make-block 'network 'online
		path: "/org/freedesktop/NetworkManager")
    (make-block 'timezone 'timezone
		path: "/org/freedesktop/timedate1")
    (make-block 'clock 'clock)))

;; Blocks by name, rather than by their position in swaybar-blocks.
(define (swaybar-block name)
  (let loop ((blocks swaybar-blocks))
    (cond ((null? blocks) #f)
	  ((string=? (symbol->string (block-name (car blocks)))
		     (symbol->string name))
	   (car blocks))
	  (else (loop (cdr blocks))))))

;; Force a re-read of every block, for after poking at them by hand.
(define (swaybar-refresh!)
  (for-each (lambda (block) (set-block-dirty! block #t)) swaybar-blocks))

;; --- block handlers -------------------------------------------------------
;;
;; Each handler takes no arguments and returns the text to display. A helper
;; a handler calls is captured when the handler is defined, so after changing
;; one, redefine the handler too.

(define (dbus-get-property service path interface property)
  (get-property
    (make-context bus: system-bus
		  service: service
		  path: path
		  interface: interface)
    property))

(define (battery-percentage)
  (format "BAT: ~a%"
	  (inexact->exact
	    (floor (dbus-get-property 'org.freedesktop.UPower
				      "/org/freedesktop/UPower/devices/DisplayDevice"
				      'org.freedesktop.UPower.Device
				      'Percentage)))))

(define (network-state-name state)
  ;; https://www.networkmanager.dev/docs/api/latest/nm-dbus-types.html#NMState
  (cond ((= state 10) "offline")
	((or (= state 20) (= state 30)) "disconnecting")
	((= state 40) "connecting")
	((= state 50) "offline")
	((= state 60) "online*")
	((= state 70) "online")
	(else "unknown")))

(define (online)
  (let ((state (dbus-get-property 'org.freedesktop.NetworkManager
				  "/org/freedesktop/NetworkManager"
				  'org.freedesktop.NetworkManager
				  'State)))
    (format "NET: ~a" (if state (network-state-name state) "unknown"))))

(define (timezone)
  (let ((tz (dbus-get-property 'org.freedesktop.timedate1
			       "/org/freedesktop/timedate1"
			       'org.freedesktop.timedate1
			       'Timezone)))
    (format "TZ: ~a" tz)))

(define (clock)
  (time->string (seconds->local-time (current-seconds)) "%D %T"))

;; --- rendering ------------------------------------------------------------

;; Run THUNK; return its value, or the condition it raised. CHICKEN 6's
;; handle-exceptions takes the fail expression first and binds the exception
;; in it, so a bare e hands back the condition itself.
(define (catch-error thunk)
  (handle-exceptions e e (thunk)))

(define (condition-message condition)
  (get-condition-property condition 'exn 'message))

(define (textify x)
  (cond ((string? x) x)
	((number? x) (number->string x))
	((symbol? x) (symbol->string x))
	(else (call-with-output-string (lambda (port) (write x port))))))

;; A json object for the json egg: a vector of pairs. CHICKEN 6's #(...) is a
;; data literal, so the pairs have to be built rather than written inline.
(define (json-object . pairs)
  (list->vector pairs))

;; Tab-separated to stderr; stdout belongs to sway's json protocol.
(define (swaybar-log . args)
  (let loop ((args args))
    (when (pair? args)
      (display (textify (car args)) (current-error-port))
      (when (pair? (cdr args)) (display "\t" (current-error-port)))
      (loop (cdr args))))
  (display "\n" (current-error-port)))

;; A block's handler is either a procedure or, as the blocks above use, the
;; name of one. A name is resolved with eval on every tick, so re-evaluating
;; its definition over the repl changes what the bar runs -- that is the
;; whole point of the indirection. The name in the repl is the live
;; implementation, which is what to hold on to when wrapping one rather than
;; replacing it:
;;
;;   (define plain-timezone timezone)
;;   (define (timezone) (string-append "\U0001F552 " (plain-timezone)))
(define (block-fn block)
  (let ((handler (block-handler block)))
    (if (procedure? handler) handler (eval handler))))

;; The frame a block renders when its handler fails; logged once per distinct
;; message, the bar keeps ticking.
(define (block-error-frame block condition)
  (let ((message (condition-message condition)))
    (unless (equal? message (block-last-error block))
      (set-block-last-error! block message)
      (swaybar-log "swaybar: block" (block-name block) "failed:" message))
    (json-object
      (cons 'name (symbol->string (block-name block)))
      (cons 'full_text (format "~a: error" (block-name block)))
      (cons 'color "#ff0000"))))

(define (render-block block handler)
  (let ((result (catch-error (lambda () (handler)))))
    (if (condition? result)
      (block-error-frame block result)
      (begin
	(set-block-last-error! block #f)
	(json-object
	  (cons 'name (symbol->string (block-name block)))
	  (cons 'full_text (textify result)))))))

;; The frame a block contributes on this tick. A dbus-driven block keeps its
;; last value until a signal invalidates it, except that a handler or a path
;; that is not the one it last rendered with -- a definition re-evaluated
;; over the repl -- always takes effect here.
(define (block-frame block)
  (let ((handler (catch-error (lambda () (block-fn block)))))
    (if (condition? handler)
      (block-error-frame block handler)
      (begin
	(when (or (block-dirty block)
		  (not (block-json block))
		  (not (block-path block))
		  (not (eq? (block-rendered-handler block) handler))
		  (not (equal? (block-rendered-path block) (block-path block))))
	  (set-block-dirty! block #f)
	  (set-block-rendered-handler! block handler)
	  (set-block-rendered-path! block (block-path block))
	  (set-block-json! block (render-block block handler)))
	(block-json block)))))

;; --- dbus matches ---------------------------------------------------------

;; Everything an object emits, rather than picking out PropertiesChanged:
;; some services (NetworkManager) announce changes with signals of their own
;; as well.
(define (signal-match path)
  (format "type='signal',path=~a" (string-append "'" path "'")))

;; The paths the bar has match rules installed for. Blocks are just a list
;; someone edits from the repl, so rather than subscribing and unsubscribing
;; as that happens, bring the rules we hold in line with the paths the blocks
;; ask for.
(define matched-paths '())

(define (reconcile-matches!)
  (let* ((wanted (delete-duplicates (filter-map block-path swaybar-blocks)))
	 (to-add (lset-difference string=? wanted matched-paths))
	 (to-remove (lset-difference string=? matched-paths wanted)))
    (for-each (lambda (path) (add-match-rule system-bus (signal-match path)))
	      to-add)
    (for-each (lambda (path) (remove-match-rule system-bus (signal-match path)))
	      to-remove)
    (set! matched-paths wanted)))

;; A signal from an object some block subscribed to marks that block for a
;; re-read. Runs on the main thread while poll-for-message drains the bus.
(default-signal-handler
  (lambda (context member args)
    (let ((path (symbol->string (context-path context))))
      (for-each
	(lambda (block)
	  (when (and (block-path block) (string=? path (block-path block)))
	    (set-block-dirty! block #t)))
	swaybar-blocks))))

(define (render!)
  (reconcile-matches!)
  (map block-frame swaybar-blocks))

;; --- the bar itself -------------------------------------------------------

(define (emit-frame blocks)
  (json-write blocks (current-output-port))
  (display "," (current-output-port))
  (flush-output (current-output-port)))

;; Sway wants the protocol header before anything else, and getting it out
;; before any of the work below means nothing can delay the bar appearing.
(json-write #((version . 1)) (current-output-port))
(display "\n[" (current-output-port))
(flush-output (current-output-port))

;; Take whatever the bus has queued for us; a signal from an object some
;; block subscribed to marks that block for a re-read.
(define (drain-bus!)
  (let loop ()
    (when (poll-for-message bus: system-bus timeout: 0) (loop))))

(define last-tick-error #f)

(define (main-loop)
  (let loop ((next-tick (+ (current-seconds) (min 1 swaybar-interval))))
    ;; A broken block list from the repl, or a bus that is not up yet,
    ;; should cost one bad tick rather than take the bar down.
    (let ((result (catch-error render!)))
      (if (condition? result)
	(let ((message (condition-message result)))
	  (unless (equal? message last-tick-error)
	    (set! last-tick-error message)
	    (swaybar-log "swaybar: render failed:" message))
	  (emit-frame
	    (list (json-object
		    (cons 'name "swaybar")
		    (cons 'full_text message)
		    (cons 'color "#ff0000")))))
	(begin
	  (set! last-tick-error #f)
	  (emit-frame result))))
    ;; Rendering reads from the bus and can leave signals sitting in libdbus'
    ;; queue where they no longer make the socket readable, so drain before
    ;; blocking; the poll timeout is only a backstop, signals normally wake
    ;; us early. A bus that fails here costs one bad tick like any other.
    (let ((wait (catch-error
		  (lambda ()
		    (drain-bus!)
		    ;; Wait for the next tick in short slices with a yield
		    ;; between them: a long read_write holds the runtime's
		    ;; global lock and starves every other thread -- most
		    ;; importantly the repl's, which can then neither accept
		    ;; connections nor read from them. A slice that comes back
		    ;; with a signal ends the wait early so the bar redraws
		    ;; right away.
		    (let loop ((woken #f))
		      (when (and (not woken) (< (current-seconds) next-tick))
			(thread-sleep! 0.01)
			(loop (poll-for-message bus: system-bus timeout: 100))))))))
      (when (condition? wait)
	(let ((message (condition-message wait)))
	  (unless (equal? message last-tick-error)
	    (set! last-tick-error message)
	    (swaybar-log "swaybar: watching the bus failed:" message))
	  (thread-sleep! 1.0)))
      (loop (+ (current-seconds) (min 1 swaybar-interval))))))

;; --- repl -----------------------------------------------------------------

;; The repl listens on a unix domain socket rather than an IP address: no
;; port to collide over, no v4/v6 to pick between, and $XDG_RUNTIME_DIR is
;; already private to the user. chicken's tcp-listen cannot build such a
;; socket (it is hardwired to AF_INET), so the listening socket is made by
;; hand; all tcp-accept needs is a file descriptor in a tcp-listener
;; structure, and accept(2) does not care which family it came from.
(define socket-error-message
  (foreign-lambda* c-string ()
		   "static char message[256];"
		   "snprintf(message, sizeof(message), \"%s\", strerror(errno));"
		   "C_return(message);"))

;; -1 for a bind/listen failure (see socket-error-message), -2 for a path
;; that does not fit in sun_path.
(define unix-socket-bind-listen
  (foreign-lambda* int ((c-string path))
		   "struct sockaddr_un addr;"
		   "if (strlen(path) >= sizeof(addr.sun_path)) C_return(-2);"
		   "int sock = socket(AF_UNIX, SOCK_STREAM, 0);"
		   "if (sock < 0) C_return(-1);"
		   ; A stale file from a dead instance would make bind fail; only this
		   ; program ever binds here, so removing it is safe.
		   "unlink(path);"
		   "memset(&addr, 0, sizeof(addr));"
		   "addr.sun_family = AF_UNIX;"
		   "strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);"
		   "if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0 || listen(sock, 5) < 0) {"
		   "  close(sock);"
		   "  C_return(-1);"
		   "}"
		   "C_return(sock);"))

;; A listening socket at PATH; the error it raises is what the caller logs.
(define (unix-repl-listen path)
  (let ((sock (unix-socket-bind-listen path)))
    (cond ((= sock -2)
	   (error (format "socket path too long: ~a" path)))
	  ((negative? sock)
	   (error (format "cannot listen on ~a: ~a" path (socket-error-message))))
	  (else
	    (##sys#make-structure 'tcp-listener sock)))))

;; Where the repl listens; $SWAYBAR_REPL_SOCK overrides, 0 turns it off.
(define (repl-socket-path)
  (let ((override (get-environment-variable "SWAYBAR_REPL_SOCK")))
    (cond ((or (equal? override "") (equal? override "0")) #f)
	  (override override)
	  (else
	    (let ((runtime (get-environment-variable "XDG_RUNTIME_DIR")))
	      (and runtime (string-append runtime (sprintf "/swaybar-repl.~a.sock" (current-process-id)))))))))

;; tcprepl evaluates in the program's global environment, so every top-level
;; definition here -- the handlers, swaybar-blocks and friends -- is
;; reachable by name and redefinable from a connection. Its prompt and
;; results go to the connected client, keeping stdout free for the bar.
(define (start-repl!)
  (let ((path (repl-socket-path)))
    ;; No socket location (no XDG_RUNTIME_DIR, repl turned off) just means no
    ;; repl; the bar itself does not need one.
    (when path
      (thread-start!
	(lambda ()
	  (handle-exceptions e
			     (swaybar-log (format "swaybar: repl on ~a failed:" path)
					  (condition-message e))
			     ;; Run the session on the accept thread itself, rather than in a
			     ;; spawned one: under CHICKEN 6, a thread created while the main
			     ;; thread is inside a dbus call never runs.
			     (let ((listener (unix-repl-listen path)))
			       (swaybar-log (format "swaybar: repl on ~a" path))
			       (let accept ()
				 (let-values (((in out) (tcp-accept listener)))
				   (parameterize ((tcp-read-timeout #f)
						  (current-input-port in)
						  (current-output-port out)
						  (current-error-port out))
				     (tcprepl-loop)
				     (accept)))))))))))

(start-repl!)
(main-loop)
