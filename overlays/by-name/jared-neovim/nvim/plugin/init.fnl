(vim.loader.enable)

(local fzf-lua (require :fzf-lua))
(local mini-misc (require :mini.misc))
(local nvim-treesitter-configs (require :nvim-treesitter.configs))
(local paredit (require :nvim-paredit))
(paredit.setup)

(local is-dumb-term (not= (: (vim.regex "linux\\|vt220\\|vt202\\|dumb")
                             :match_str vim.env.TERM)
                          nil))

(mini-misc.setup_restore_cursor)
(when (not is-dumb-term)
  (mini-misc.setup_termbg_sync))

(vim.api.nvim_set_hl 0 :ExtraWhitespace {:bg :red})
(vim.cmd.match "ExtraWhitespace /\\s\\+$/")
(vim.api.nvim_create_autocmd [:TextYankPost]
                             {:group (vim.api.nvim_create_augroup :TextYankPost
                                                                  {:clear true})
                              :pattern "*"
                              :callback (lambda []
                                          (vim.hl.on_yank {:higroup :Visual
                                                           :timeout 300})
                                          nil)})

(vim.api.nvim_create_autocmd [:TermOpen]
                             {:group (vim.api.nvim_create_augroup :TermOpen
                                                                  {:clear true})
                              :callback (lambda []
                                          (local ns-id
                                                 (vim.api.nvim_create_namespace :terminal))
                                          (vim.api.nvim_win_set_hl_ns (vim.api.nvim_get_current_win)
                                                                      ns-id)
                                          (vim.api.nvim_set_hl ns-id
                                                               :ExtraWhitespace
                                                               {})
                                          (set vim.opt_local.spell false)
                                          (set vim.opt_local.number false)
                                          (set vim.opt_local.relativenumber
                                               false)
                                          (set vim.opt_local.signcolumn :no)
                                          (vim.cmd.startinsert)
                                          nil)})

(fn setup-fzf [?background]
  (fzf-lua.setup {:fzf_args (string.format "--color=%s" (or ?background :dark))
                  :defaults {:file_icons false}
                  :files {:previewer false}
                  :hls {:title "" :title_flags ""}
                  :winopts {:split "botright 15new"
                            :border false
                            :preview {:hidden true
                                      :border nil
                                      :title false
                                      :layout :horizontal
                                      :horizontal "right:50%"}}})
  nil)

; Do the initial setup of fzf such that we don't start with the defaults.
(setup-fzf)

(vim.api.nvim_create_autocmd [:OptionSet]
                             {:pattern [:background]
                              :callback (lambda [opts]
                                          (if (= (. opts :match) :background)
                                              (setup-fzf (vim.opt.background:get)))
                                          nil)})

(nvim-treesitter-configs.setup {:indent {:enable true}
                                :highlight {:enable true
                                            :additional_vim_regex_highlighting false}
                                :incremental_selection {:enable true
                                                        :keymaps {:init_selection :gnn
                                                                  :node_incremental :grn
                                                                  :scope_incremental :grc
                                                                  :node_decremental :grm}}})

(set vim.g.clipboard :osc52)
(set vim.g.dispatch_no_tmux_make 1)
(set vim.g.loaded_perl_provider 0)
(set vim.g.loaded_python3_provider 0)
(set vim.g.mapleader (vim.api.nvim_replace_termcodes :<Space> true true true))
(set vim.g.maplocalleader ",")
(set vim.g.zoxide_hook :pwd)
(set vim.g.zoxide_use_select 1)

(set vim.wo.foldenable false)
(set vim.wo.foldexpr "v:lua.vim.treesitter.foldexpr()")
(set vim.wo.foldmethod :expr)
(set vim.wo.foldminlines 20)
(set vim.wo.foldnestmax 1)

(set vim.opt.autoread true)
(set vim.opt.breakindent true)
(set vim.opt.clipboard :unnamedplus)
(set vim.opt.colorcolumn :80)
(set vim.opt.completeopt (table.concat [:menuone :noselect] ","))
(set vim.opt.hidden true)
(set vim.opt.hlsearch true)
(set vim.opt.ignorecase true)
(set vim.opt.incsearch true)
(set vim.opt.infercase true)
(set vim.opt.laststatus 2)
(set vim.opt.linebreak true)
(set vim.opt.number true)
(set vim.opt.ruler true)
(vim.opt.shortmess:remove [:S])
(set vim.opt.showcmd true)
(set vim.opt.showmatch true)
(set vim.opt.smartcase true)
(set vim.opt.smartindent true)
(set vim.opt.splitbelow true)
(set vim.opt.splitkeep :screen)
(set vim.opt.splitright true)
(set vim.opt.termguicolors (not is-dumb-term))

(set vim.opt.title true)
(set vim.opt.virtualedit :block)
(set vim.opt.wildoptions (table.concat [:pum :tagfile] ","))
(set vim.opt.wrap false)

(vim.cmd.colorscheme (or (= (vim.opt.termguicolors:get) true) :vim :lunaperche))

; TODO(jared): use vim.snippet
(vim.cmd.iabbrev "todo:" "TODO(jared):")

(fzf-lua.register_ui_select)

(vim.keymap.set :n :<Leader>? fzf-lua.helptags {:desc "Find help tags"})
(vim.keymap.set :n :<Leader>_ fzf-lua.registers {:desc "Find registers"})
(vim.keymap.set :n :<Leader>b fzf-lua.buffers {:desc "Find buffers"})
(vim.keymap.set :n :<Leader>c fzf-lua.resume {:desc "Resume picker"})
(vim.keymap.set :n :<Leader>f fzf-lua.files {:desc "Find files"})
(vim.keymap.set :n :<Leader>g fzf-lua.live_grep {:desc "Find regexp pattern"})
(vim.keymap.set :n :<Leader>h fzf-lua.command_history
                {:desc "Find Ex-mode history"})

nil
