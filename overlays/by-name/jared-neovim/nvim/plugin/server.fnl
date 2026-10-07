;; Keep the server running if the UI disconnects unexpectedly (e.g. the
;; terminal is closed or an SSH connection drops). Errors without a UI.
(pcall vim.cmd "silent detach!")

(fn detached-server [path]
  (let [(ok chan) (pcall vim.fn.sockconnect :pipe path {:rpc true})]
    ;; Stale sockets from dead servers fail to connect.
    (when (and ok (> chan 0))
      (let [(ok uis) (pcall vim.rpcrequest chan :nvim_list_uis)
            (_ cwd) (pcall vim.rpcrequest chan :nvim_call_function :getcwd [])]
        (vim.fn.chanclose chan)
        (if (and ok (= 0 (length uis)))
            {: path : cwd})))))

(fn detached-servers []
  (icollect [_ path (ipairs (vim.fn.glob (.. (vim.fn.stdpath :run) :/nvim.*.0)
                                         false true))]
    (if (not= path vim.v.servername)
        (detached-server path))))

(fn empty-startup? []
  ;; No files, stdin, or startup commands (e.g. MANPAGER="nvim +Man!") that
  ;; would be lost by connecting elsewhere.
  (and (= 0 (vim.fn.argc)) (= "" (vim.api.nvim_buf_get_name 0))
       (not vim.bo.modified) (= 1 (vim.fn.line "$")) (= "" (vim.fn.getline 1))
       (> (length (vim.api.nvim_list_uis)) 0)))

(vim.api.nvim_create_autocmd :VimEnter
                             {:once true
                              :callback (λ []
                                          (when (empty-startup?)
                                            (let [servers (detached-servers)]
                                              (when (> (length servers) 0)
                                                (vim.ui.select servers
                                                               {:prompt "Connect to detached Nvim server?"
                                                                :format_item (λ [server]
                                                                               (string.format "%s (%s)"
                                                                                              server.cwd
                                                                                              server.path))}
                                                               (λ [server]
                                                                 ;; ! stops this (empty) server once the UI leaves it.
                                                                 (when server
                                                                   (vim.cmd.connect {:args [server.path]
                                                                                     :bang true}))))))))})
