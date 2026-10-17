(macro qftitle []
  `(. (vim.fn.getqflist {:title true}) :title))

; TODO(jared): get this working so we can re-execute what produced a {qf,loc}list
; (vim.keymap.set :n :gr (fn [_opts?]
;                          (vim.cmd (qftitle)))
;                 {:buf 0})

(vim.keymap.set :n :g? (fn [_opts?]
                         (vim.print (qftitle))) {:buf 0})

(vim.keymap.set :n :q (fn [_opts?]
                        (vim.cmd.cclose)) {:buf 0})
