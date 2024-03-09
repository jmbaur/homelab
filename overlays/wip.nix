{ writeShellScriptBin }:
writeShellScriptBin "wip" ''
  remote=origin

  for possible_remote in jmbaur jbaur; do
    if git config remote.$possible_remote.url >/dev/null; then
      remote=$possible_remote
      break
    fi
  done

  git commit --no-verify --no-gpg-sign --all --message "WIP"; git push "$remote"
''
