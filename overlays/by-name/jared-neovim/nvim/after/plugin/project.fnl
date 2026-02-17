(fn project-dir []
  (vim.fs.joinpath (or vim.env.XDG_STATE_DIR
                       (vim.fs.joinpath vim.env.HOME :.local :state))
                   :projects))

(fn open-project [opts]
  (local project-path (vim.fs.joinpath (project-dir) opts.args))
  (if (vim.uv.fs_stat project-path)
      (do
        (vim.cmd.tabnew project-path)
        (vim.cmd.tcd project-path))
      (vim.print (string.format "Project does not exist at %s" project-path))))

(fn project-complete [arg-lead cmdline cursor-pos]
  (icollect [name entry-type (vim.fs.dir (project-dir) {:depth 1})]
    (when (= entry-type :directory)
      (if (not= -1 (vim.fn.match name arg-lead))
          name))))

(vim.api.nvim_create_user_command :Project open-project
                                  {:desc "Open new tab at directory for project"
                                   :complete project-complete
                                   :nargs 1})

nil
