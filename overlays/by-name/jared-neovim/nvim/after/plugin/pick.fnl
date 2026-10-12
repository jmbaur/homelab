;; nvim-fzy provides vim.ui.select, which qwahl's pickers are built on.
(local fzy (require :fzy))
(local qwahl (require :qwahl))

(local picker-height 11)

;; Show fzy in a strip along the bottom of the editor, like the tmux project
;; picker, instead of centered over most of it.
(set fzy.new_popup (λ []
                     (let [buf (vim.api.nvim_create_buf false true)
                           win (vim.api.nvim_open_win buf true
                                                      {:relative :editor
                                                       :style :minimal
                                                       :row (- vim.o.lines
                                                               vim.o.cmdheight
                                                               picker-height)
                                                       :col 0
                                                       :width vim.o.columns
                                                       :height picker-height})]
                       (vim.keymap.set :t :<Esc> "<C-\\><C-c>" {:buffer buf})
                       (set (. vim.bo buf :bufhidden) :wipe)
                       (values win buf))))

;; fzy runs through 'shell', whose startup files can rebuild PATH without the
;; wrapper's runtime dependencies, so use the path nvim resolves it to. fzy's
;; prompt takes a line, leave it out of the lines for results. opts.prompt is
;; already shell escaped.
(local fzy-exe (vim.fn.shellescape (vim.fn.exepath :fzy)))
(set fzy.command
     (λ [opts]
       (.. fzy-exe " -l " (- opts.height 1)
           (if opts.prompt (.. " -p " opts.prompt) ""))))

;; Same file list as 'findfunc', fd is resolved for the same reason as fzy.
(local fd-command (.. (vim.fn.shellescape (vim.fn.exepath :fd)) " --type file"))

(vim.keymap.set :n :<leader>f
                #(fzy.execute fd-command fzy.sinks.edit_file "File: ")
                {:desc "Pick file"})

(vim.keymap.set :n :<leader>s qwahl.lsp_tags {:desc "Pick LSP symbol"})
(vim.keymap.set :n :<leader>/ qwahl.buf_lines {:desc "Pick buffer line"})
(vim.keymap.set :n :<leader>d #(qwahl.diagnostic 0)
                {:desc "Pick buffer diagnostic"})

(vim.keymap.set :n :<leader>D qwahl.diagnostic {:desc "Pick any diagnostic"})
(vim.keymap.set :n :<leader>q qwahl.quickfix {:desc "Pick quickfix entry"})
(vim.keymap.set :n :<leader>j qwahl.jumplist {:desc "Pick jumplist entry"})

nil
