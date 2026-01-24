(fn add-lsp-if-has [executables name ?opts]
  (if (= (length executables)
         (accumulate [sum 0 _ value (ipairs executables)]
           (+ sum (vim.fn.executable value))))
      (do
        (vim.lsp.config name (if (not= ?opts nil) ?opts {}))
        (vim.lsp.enable name)
        nil)))

(add-lsp-if-has [:bash-language-server] :bashls)
(add-lsp-if-has [:clangd] :clangd nil)
(add-lsp-if-has [:dts-lsp] :dts_lsp)
(add-lsp-if-has [:fennel-ls] :fennel_ls)
(add-lsp-if-has [:nixd] :nixd)
(add-lsp-if-has [:pyright-langserver] :pyright)
(add-lsp-if-has [:tofu-ls :tofu] :tofu_ls)
(add-lsp-if-has [:zls] :zls {:settings {:zls {:semantic_tokens :partial}}})
(add-lsp-if-has [:lua-language-server] :lua_ls)
(add-lsp-if-has [:tsgo] :tsgo)
(add-lsp-if-has [:latexmk] :texlab
                {:settings {:texlab {:latexFormatter (if (= (vim.fn.executable :tex-fmt)
                                                            1)
                                                         :tex-fmt
                                                         nil)}}})

(add-lsp-if-has [:gopls :go] :gopls
                {:settings {:gopls {:gofumpt (= (vim.fn.executable :gofumpt) 1)
                                    :staticcheck (= (vim.fn.executable :staticcheck)
                                                    1)}}})

(add-lsp-if-has [:rust-analyzer] :rust_analyzer
                {:settings {:rust-analyzer {:diagnostics {:disabled [:unresolved-proc-macro]}
                                            :check {:command (if (= (vim.fn.executable :cargo-clippy)
                                                                    1)
                                                                 :clippy
                                                                 :check)}}}})

(vim.lsp.config "*" {:root_markers [:.git]})

(local format-on-save-group
       (vim.api.nvim_create_augroup :FormatOnSave {:clear true}))

(fn lsp-attach [opts]
  (set vim.opt_local.signcolumn :yes)
  (if (vim.tbl_contains [:zig :nix :go :sh :bash :rust :terraform :tex :fennel]
                        (vim.fn.getbufvar opts.buf :&filetype))
      (vim.api.nvim_create_autocmd [:BufWritePre]
                                   {:group format-on-save-group
                                    :buffer opts.buf
                                    :callback (lambda []
                                                (and (vim.lsp.buf_is_attached 0
                                                                              opts.data.client_id)
                                                     (not vim.g.no_format_on_save)
                                                     (vim.lsp.buf.format))
                                                nil)}))
  nil)

(vim.api.nvim_create_autocmd [:LspAttach]
                             {:desc "Set mappings in LSP-enabled buffers"
                              :group (vim.api.nvim_create_augroup :LspAttach
                                                                  {:clear true})
                              :callback lsp-attach})

(fn lsp-detach [opts]
  (set vim.opt_local.signcolumn :no)
  (local client (vim.lsp.get_client_by_id opts.data.client_id))
  (and (not= client nil) (client:supports_method :textDocument/formatting)
       (vim.api.nvim_clear_autocmds {:event [:BufWritePre]
                                     :group format-on-save-group
                                     :buffer opts.buf}))
  nil)

(vim.api.nvim_create_autocmd [:LspDetach]
                             {:desc "Teardown for LSP-enabled buffers"
                              :group (vim.api.nvim_create_augroup :LspDetach
                                                                  {:clear true})
                              :callback lsp-detach})

(vim.api.nvim_create_user_command :ToggleFormatOnSave
                                  (lambda [opts]
                                    (if (or opts.bang vim.g.no_format_on_save)
                                        (set vim.g.no_format_on_save nil)
                                        (set vim.g.no_format_on_save true)))
                                  {:bang true
                                   ; forcefully enable format on save
                                   :desc "Toggle format on save for LSP-enabled buffers"})

; NOTE: fnlfmt will attempt to resolve this unicode character

;; fnlfmt: skip
(local diagnostic-sign "\u{2759}")

(vim.diagnostic.config {:signs {:text (doto []
                                        (tset vim.diagnostic.severity.ERROR
                                              diagnostic-sign)
                                        (tset vim.diagnostic.severity.WARN
                                              diagnostic-sign)
                                        (tset vim.diagnostic.severity.INFO
                                              diagnostic-sign)
                                        (tset vim.diagnostic.severity.HINT
                                              diagnostic-sign))}})

nil
