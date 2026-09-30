(import
  base64
  (chicken format)
  (chicken io)
  (chicken process-context))

(define (osc52 input output)
  (define in-tmux (get-environment-variable "TMUX"))
  (fprintf output "~A\x1b;]52;c;~A\x07;~A"
	   (if in-tmux "\x1b;Ptmux;\x1b;" "")
	   (base64-encode input)
	   (if in-tmux "\x1b;\\" "")))

(osc52 (current-input-port) (current-output-port))
