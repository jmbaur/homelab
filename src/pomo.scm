(import
  (chicken condition)
  (chicken format)
  (chicken io)
  (chicken process)
  (chicken process-context)
  (chicken time))

;; Displays the message to the terminal as well as sends a notification through
;; the terminal via OSC 777.
(define (message text)
  (write-line text)
  (printf "\x1b;]777;notify;pomodoro;~a\x07;~!" text))

(define (cycle-duration seconds)
  (* 60 seconds))

(define (pomo cycle depth)
  (cond
    ((equal? cycle 'work) (begin
			    (message "work!")
			    (process-sleep (cycle-duration 25))
			    (pomo 'break depth)))
    ((equal? cycle 'break) (begin
			     (message "break!")
			     (process-sleep (cycle-duration 5))
			     (if (= depth 4)
			       (pomo 'long-break 0)
			       (pomo 'work (+ 1 depth)))))
    ((equal? cycle 'long-break) (begin
				  (message "long break!")
				  (process-sleep (cycle-duration 30))
				  (write-line "Press <ENTER> to continue into the next pomodoro session, <CTRL-C> to quit.")
				  (read-line)
				  (pomo 'work 0)))))

(printf "\x1b;[2J\x1b;[0;0H~!") ; clear the screen
(pomo 'work 0)
