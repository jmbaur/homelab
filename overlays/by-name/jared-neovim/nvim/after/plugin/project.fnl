(fn project-dir []
  (vim.fs.joinpath (or vim.env.XDG_STATE_DIR
                       (vim.fs.joinpath vim.env.HOME :.local :state))
                   :projects))

(fn collect-projects []
  (icollect [name entry-type (vim.fs.dir (project-dir) {:depth 1})]
    (when (= entry-type :directory)
      name)))

(fn open-project [opts]
  (let [project-path (vim.fs.joinpath (project-dir) opts.args)]
    (if (vim.uv.fs_stat project-path)
        (do
          (if opts.bang
              (vim.cmd.tabnew project-path))
          (vim.cmd.tcd project-path)
          (if (not opts.bang)
              (vim.cmd.edit project-path)))
        (let [candidates (vim.fn.matchfuzzy (collect-projects) opts.args)]
          (if (= (length candidates) 1)
              (do
                (set opts.args (. candidates 1))
                (open-project opts))
              (vim.print (string.format "Project does not exist at %s"
                                        project-path)))))))

(fn project-complete [arg-lead _cmdline _cursor-pos]
  (let [candidates (collect-projects)]
    (if (= (string.len arg-lead) 0)
        candidates
        (vim.fn.matchfuzzy candidates arg-lead))))

(vim.api.nvim_create_user_command :Project open-project
                                  {:desc "Open new tab at directory for project"
                                   :complete project-complete
                                   :bang true
                                   :nargs 1})

nil
