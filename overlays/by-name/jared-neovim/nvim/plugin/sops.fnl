;; Edit sops-encrypted files in place instead of through `sops edit` with a
;; nested nvim. sops runs in a terminal split so age plugins (e.g.
;; age-plugin-fido2-hmac) can prompt for PINs and touches on its tty.

(fn sops-file? [buf]
  (vim.api.nvim_buf_call buf
                         (λ []
                           (and (not= 0
                                      (vim.fn.search "\\v^\\s*\"?sops(\"?:|_mac\\=)"
                                                     :nw))
                                (not= 0 (vim.fn.search "ENC\\[AES256_GCM" :nw))))))

(fn run-sops [args env on-success]
  "Run sops in a terminal split, closing it and calling `on-success` when sops
  exits with one of the given codes. On failure the split stays open to show
  sops' error."
  (let [win (vim.api.nvim_get_current_win)]
    (vim.cmd "botright 10new")
    (let [term-buf (vim.api.nvim_get_current_buf)]
      (vim.fn.jobstart (vim.list_extend [:sops] args)
                       {:term true
                        : env
                        :on_exit (λ [_ code _]
                                   (if (or (= code 0) (= code 200))
                                       (do
                                         (if (vim.api.nvim_buf_is_valid term-buf)
                                             (vim.api.nvim_buf_delete term-buf
                                                                      {:force true}))
                                         (if (vim.api.nvim_win_is_valid win)
                                             (vim.api.nvim_set_current_win win))
                                         (on-success))
                                       (vim.notify (string.format "sops exited with code %d"
                                                                  code)
                                                   vim.log.levels.ERROR)))}))))

(fn set-plaintext [buf lines]
  ;; Keep the ciphertext and plaintext out of undo history.
  (let [undolevels (. vim.bo buf :undolevels)]
    (tset vim.bo buf :undolevels -1)
    (tset vim.bo buf :modifiable true)
    (vim.api.nvim_buf_set_lines buf 0 -1 false lines)
    (tset vim.bo buf :undolevels undolevels)
    (tset vim.bo buf :modified false)))

(fn write [buf path]
  (let [plaintext (vim.fn.tempname)]
    (vim.fn.writefile (vim.api.nvim_buf_get_lines buf 0 -1 false) plaintext)
    (run-sops [:edit path]
              ;; sops appends the path of its decrypted copy to the editor
              ;; command, so this overwrites it with the buffer's contents.
              {:SOPS_EDITOR (.. "cp -- " plaintext)}
              (λ []
                (vim.fn.delete plaintext)
                (if (vim.api.nvim_buf_is_valid buf)
                    (tset vim.bo buf :modified false))
                (vim.notify (.. "sops: wrote " path))))))

(fn decrypt [buf path]
  (let [plaintext (vim.fn.tempname)]
    (tset vim.bo buf :modifiable false)
    (run-sops [:decrypt :--output plaintext path] nil
              (λ []
                (let [lines (vim.fn.readfile plaintext)]
                  (vim.fn.delete plaintext)
                  (when (vim.api.nvim_buf_is_valid buf)
                    (set-plaintext buf lines)
                    ;; acwrite routes :w through BufWriteCmd and stops nvim
                    ;; reloading the (still encrypted) file when sops rewrites it.
                    (tset vim.bo buf :buftype :acwrite)
                    (tset vim.b buf :sops_path path)
                    (vim.api.nvim_clear_autocmds {:event :BufWriteCmd
                                                  :buffer buf})
                    (vim.api.nvim_create_autocmd :BufWriteCmd
                                                 {:buffer buf
                                                  :callback (λ []
                                                              (write buf path))})))))))

(local group (vim.api.nvim_create_augroup :Sops {:clear true}))

;; Writing a buffer to another file (`:w other`, `:w >> other`, `:saveas`)
;; bypasses its BufWriteCmd, so stop decrypted buffers from leaking that way.
(vim.api.nvim_create_autocmd [:BufWritePre :FileWritePre :FileAppendPre]
                             {: group
                              :callback (λ [{: file}]
                                          (let [path (. vim.b :sops_path)]
                                            (if (and path
                                                     (not= path
                                                           (vim.fn.fnamemodify file
                                                                               ":p")))
                                                (error "sops: refusing to write decrypted secrets to another file"
                                                       0))))})

(vim.api.nvim_create_autocmd :BufReadPost
                             {: group
                              :pattern ["*.yaml" "*.yml" "*.json" "*.env"]
                              :callback (λ [{: buf : file}]
                                          (when (sops-file? buf)
                                            ;; Don't leave plaintext on disk.
                                            (tset vim.bo buf :swapfile false)
                                            (tset vim.bo buf :undofile false)
                                            (decrypt buf
                                                     (vim.fn.fnamemodify file
                                                                         ":p")))
                                          nil)})
