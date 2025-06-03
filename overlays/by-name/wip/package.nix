{ writeShellApplication, git }:

writeShellApplication {
  name = "wip";
  runtimeInputs = [ git ];
  text = ''
    git commit --no-verify --no-gpg-sign --all --message "WIP"
  '';
}
