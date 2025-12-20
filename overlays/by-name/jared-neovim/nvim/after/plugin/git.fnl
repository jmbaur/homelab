(fn stdout-or-bail [result]
  (if (> result.code 0)
      (error (vim.trim result.stderr) vim.log.levels.ERROR)
      (vim.trim result.stdout)))

(fn get-range [args]
  (if (= args.range 0)
      [nil nil]
      (if (= args.line1 args.line2)
          [args.line1 nil]
          [args.line1 args.line2])))

; base_url_fmt: accepts 3 args (base url, git revision, & file path)
; line1_fmt: accepts 1 arg (line 1)
; line2_fmt: accepts 1 arg (line 2)
(fn construct-url [base-url-fmt line1-fmt line2-fmt]
  (lambda [args remote-url rev git-file]
    (let [(line1 line2) (unpack (get-range args))]
      (var url (string.format base-url-fmt remote-url rev git-file))
      (if (not= line1 nil)
          (set url (.. url (string.format line1-fmt line1))))
      (if (not= line2 nil)
          (set url (.. url (string.format line2-fmt line2))))
      url)))

(local forges
       {:github (construct-url "%s/blob/%s/%s" "#L%s" "-L%s")
        :gitlab (construct-url "%s/-/blob/%s/%s" "#L%s" "-%s")
        :sourcehut (construct-url "%s/tree/%s/item/%s" "#L%s" "-%s")
        :gitea (construct-url "%s/src/commit/%s/%s" "#L%s" "-L%s")})

(local github-header-regex (vim.regex "^x-github-request-id: .*$"))
(local gitlab-header-regex (vim.regex "^x-gitlab-meta: .*$"))
(local gitea-header-regex (vim.regex "^set-cookie: .*i_like_gitea.*$"))

(fn detect-forge [remote-url]
  (local headers (vim.split (stdout-or-bail (: (vim.system [:curl
                                                            :--silent
                                                            :--head
                                                            remote-url])
                                               :wait))
                            "\r\n"))
  (local found-forge (icollect [_ header (ipairs headers)]
                       (if (github-header-regex:match_str header)
                           :github
                           (if (gitlab-header-regex:match_str header) :gitlab
                               (if (gitea-header-regex:match_str header)
                                   :gitea)))))
  (if (= (length found-forge) 0)
      (error "forge type not detected" vim.log.levels.ERROR)
      (. found-forge 1)))

(vim.api.nvim_create_user_command :Permalink
                                  (lambda [opts]
                                    (local current-file (vim.fn.expand "%"))
                                    (local repo-dir
                                           (stdout-or-bail (: (vim.system [:git
                                                                           :-C
                                                                           (vim.fs.dirname current-file)
                                                                           :rev-parse
                                                                           :--show-toplevel])
                                                              :wait)))

                                    (fn git-command [rest]
                                      (local cmd [:git :-C repo-dir])
                                      (each [_ val (ipairs rest)]
                                        (table.insert cmd val))
                                      (: (vim.system cmd) :wait))

                                    (local git-file
                                           (stdout-or-bail (git-command [:ls-files
                                                                         current-file])))
                                    (if (> (. (git-command [:diff :HEAD]) :code)
                                           0)
                                        (error "working tree is dirty"
                                               vim.log.levels.ERROR))
                                    (local remote-refspecs
                                           (vim.tbl_filter (lambda [value]
                                                             (not= (vim.fn.match value
                                                                                 ".*\\/HEAD -> .*")
                                                                   0))
                                                           (vim.split (stdout-or-bail (git-command [:branch
                                                                                                    :--points-at
                                                                                                    :HEAD
                                                                                                    :--remotes]))
                                                                      "\n")))
                                    (if (= (length remote-refspecs) 0)
                                        (error "no remote branches found that point at HEAD"
                                               vim.log.levels.ERROR))
                                    (local remote
                                           (vim.trim (vim.fn.substitute (. remote-refspecs
                                                                           1)
                                                                        "\\/.*"
                                                                        "" "")))
                                    (local remote-url
                                           (string.gsub (stdout-or-bail (git-command [:remote
                                                                                      :get-url
                                                                                      remote]))
                                                        "git%+ssh://.*@"
                                                        "https://"))
                                    (local rev
                                           (stdout-or-bail (git-command [:rev-parse
                                                                         :HEAD])))
                                    (var forge-fn nil)
                                    (each [_ forge (ipairs [[:github
                                                             "^https?://github.com/.*$"]
                                                            [:gitlab
                                                             "^https?://gitlab.com/.*$"]
                                                            [:sourcehut
                                                             "^https://git.sr.ht/.*$"]
                                                            [:gitea
                                                             "^https://codeberg.org/.*$"]])]
                                      (when (string.match remote-url
                                                          (. forge 2))
                                        (set forge-fn (. forges (. forge 1)))))
                                    (if (= forge-fn nil)
                                        (do
                                          (var forge
                                               (vim.trim (. (git-command [:config
                                                                          :get
                                                                          (string.format "remote.%s.forge-type"
                                                                                         remote)])
                                                            :stdout)))
                                          (if (= forge "")
                                              (set forge
                                                   (detect-forge remote-url))
                                              (git-command [:config
                                                            :set
                                                            (string.format "remote.%s.forge-type"
                                                                           remote)
                                                            forge]))
                                          (set forge-fn (. forges forge))))
                                    (if (= forge-fn nil)
                                        (error "unknown forge type"
                                               vim.log.levels.ERROR))
                                    (local url
                                           (forge-fn opts remote-url rev
                                                     git-file))
                                    (if opts.bang
                                        (vim.fn.setreg "+" url))
                                    (vim.print url)
                                    nil)
                                  {:range true
                                   :bang true
                                   :desc "Get a permalink to source at line under cursor or selected range"})

nil
