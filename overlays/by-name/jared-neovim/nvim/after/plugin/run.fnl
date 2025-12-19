(fn nix-path-contains-nixpkgs []
  (not= (vim.fn.match (vim.trim (. (: (vim.system [:nix
                                                   :config
                                                   :show
                                                   :nix-path])
                                      :wait)
                                   :stdout)) :nixpkgs) -1))

; Use a large tarball TTL value so invocations of 'nix shell' can be fast
(local max-tarball-ttl (- (math.pow 2 32) 1))

(fn nix-shell [attr command]
  (lambda []
    (if (nix-path-contains-nixpkgs)
        (string.format "nix shell --tarball-ttl %s nixpkgs\\#%s -c %s"
                       max-tarball-ttl attr command)
        (string.format "nix shell --tarball-ttl %s github:nixos/nixpkgs/master\\#%s -c %s"
                       max-tarball-ttl attr command))))

(fn nix-run [attr] (nix-shell attr attr))

(fn nix-repl [] (table.concat [:nix :repl :--tarball-ttl max-tarball-ttl] " "))

(local run-builtins {:bash (nix-run :bash)
                     :bc (nix-run :bc)
                     :deno (nix-run :deno)
                     :ghci (nix-shell :ghc :ghci)
                     :lua (nix-run :lua)
                     :nix (nix-repl)
                     :node (nix-shell :nodejs :node)
                     :python3 (nix-run :python3)
                     :sbcl (nix-run :sbcl)
                     :ecl (nix-run :ecl)
                     :guile (nix-run :guile)
                     :chicken (nix-shell :chicken :csi)})

(vim.api.nvim_create_user_command :Run
                                  (lambda [opts]
                                    (local cmd {})
                                    (if (not= "" opts.mods)
                                        (table.insert cmd opts.mods))
                                    (table.insert cmd :terminal)
                                    (if (vim.tbl_contains (vim.tbl_keys run-builtins)
                                                          opts.args)
                                        (do
                                          (local builtin
                                                 (. run-builtins opts.args))
                                          (table.insert cmd
                                                        (if (= (type builtin)
                                                               :function)
                                                            (builtin)
                                                            builtin)))
                                        (if (not= "" opts.args)
                                            (table.insert cmd
                                                          (nix-run opts.args))))
                                    (vim.fn.execute (table.concat cmd " "))
                                    nil)
                                  {:nargs "?"
                                   :complete (lambda [?arg-lead
                                                      ?cmdline
                                                      ?cursor-pos]
                                               (local candidates {})
                                               (each [_index key (ipairs (vim.tbl_keys run-builtins))]
                                                 (if (= (vim.fn.match key
                                                                      ?arg-lead)
                                                        0)
                                                     (table.insert candidates
                                                                   key)))
                                               candidates)})

nil
