(vim.loader.enable)

(local is-dumb-term (not= (: (vim.regex "linux\\|vt220\\|vt202\\|dumb")
                             :match_str vim.env.TERM)
                          nil))

(vim.api.nvim_create_autocmd [:BufRead :BufNewFile]
                             {:pattern [:*.rdl]
                              :callback (lambda []
                                          (set vim.optlocal.filetype :systemrdl)
                                          nil)})

;; TODO(jared): consider only enabling this on certain filetypes
(vim.api.nvim_create_autocmd :Filetype
                             {:callback (lambda []
                                          (if (pcall vim.treesitter.start)
                                              (do
                                                (set vim.bo.indentexpr
                                                     "v:lua.require(\"nvim-treesitter\").indentexpr()")
                                                (set vim.wo.foldexpr
                                                     "v:lua.vim.treesitter.foldexpr()")
                                                (set vim.wo.foldmethod :expr))))})

(local paste
       (lambda []
         [(vim.fn.split (vim.fn.getreg "") "\n") (vim.fn.getregtype "")]))

(set vim.g.clipboard {:name "OSC 52"
                      :copy {:+ ((. (require :vim.ui.clipboard.osc52) :copy) "+")
                             :* ((. (require :vim.ui.clipboard.osc52) :copy) "*")}
                      :paste {:+ paste :* paste}})

(set vim.g.dispatch_no_tmux_make 1)
(set vim.g.loaded_perl_provider 0)
(set vim.g.loaded_python3_provider 0)
(set vim.g.mapleader (vim.api.nvim_replace_termcodes :<Space> true true true))
(set vim.g.maplocalleader ",")
(set vim.g.direnv_silent_load 1)
; disable conjure mappings for now
(set (. vim.g "conjure#mapping#enable_defaults") false)
(set (. vim.g "conjure#mapping#enable_ft_mappings") false)

(set vim.wo.foldenable false)
(set vim.wo.foldminlines 20)
(set vim.wo.foldnestmax 1)

(set vim.opt.autoread true)
(set vim.opt.breakindent true)
(set vim.opt.clipboard :unnamedplus)
(set vim.opt.completeopt (table.concat [:menuone :noselect] ","))
(set vim.opt.hidden true)
(set vim.opt.ignorecase true)
(set vim.opt.infercase true)
(set vim.opt.linebreak true)
(set vim.opt.ruler true)
(set vim.opt.showcmd true)
(set vim.opt.showmatch true)
(set vim.opt.smartcase true)
(set vim.opt.smartindent true)
(set vim.opt.splitbelow true)
(set vim.opt.splitkeep :screen)
(set vim.opt.splitright true)
(set vim.opt.termguicolors (not is-dumb-term))

(vim.opt.shortmess:remove [:S])

(set vim.opt.title true)
(set vim.opt.virtualedit :block)
(set vim.opt.wildoptions (table.concat [:pum :fuzzy] ","))
(set vim.opt.wrap false)

((. (require :modus-themes) :setup) {:variants {:modus_operandi :tritanopia
                                                :modus_vivendi :tritanopia}
                                     :styles {:comments {:italic false}
                                              :keywords {:italic false}}})

(vim.cmd.colorscheme (if (= (vim.opt.termguicolors:get) true) :modus :vim))

; TODO(jared): use vim.snippet
(vim.cmd.iabbrev "todo:" "TODO(jared):")

(vim.keymap.set :n :<leader>p ":Project! ")

(var filescache [])
(set _G.FuzzyFind (lambda [arg _]
                    (set filescache
                         (vim.split (. (: (vim.system [:fd :--type :file])
                                          :wait)
                                       :stdout)
                                    "\n"))
                    (if (= arg "")
                        filescache
                        (vim.fn.matchfuzzy filescache arg))))

(vim.api.nvim_create_autocmd [:CmdlineEnter]
                             {:pattern [":"]
                              :callback (lambda [_]
                                          (set filescache [])
                                          nil)})

(set vim.opt.findfunc "v:lua._G.FuzzyFind")

(vim.api.nvim_create_autocmd [:TextYankPost]
                             {:group (vim.api.nvim_create_augroup :TextYankPost
                                                                  {:clear true})
                              :callback (lambda []
                                          (vim.hl.hl_op {:higroup :Visual
                                                         :timeout 300})
                                          nil)})

(vim.api.nvim_create_autocmd [:TermOpen]
                             {:group (vim.api.nvim_create_augroup :TermOpen
                                                                  {:clear true})
                              :callback (lambda []
                                          (set vim.opt_local.spell false)
                                          (set vim.opt_local.number false)
                                          (set vim.opt_local.relativenumber
                                               false)
                                          (set vim.opt_local.signcolumn :no)
                                          (vim.cmd.startinsert)
                                          nil)})

(local qfgroup (vim.api.nvim_create_augroup :QuickFix {:clear true}))
(vim.api.nvim_create_autocmd [:QuickFixCmdPost]
                             {:group qfgroup
                              :pattern "[^l]*"
                              :callback (lambda [] (vim.cmd.cwindow))})

(vim.api.nvim_create_autocmd [:QuickFixCmdPost]
                             {:group qfgroup
                              :pattern :l*
                              :callback (lambda [] (vim.cmd.lwindow))})

((. (require :vim._core.ui2) :enable) {:enable true})

nil
