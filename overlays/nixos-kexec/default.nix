{ writeShellApplication, fzf, jq }:
writeShellApplication {
  name = "nixos-kexec";
  runtimeInputs = [ fzf jq ];
  text = builtins.readFile ./nixos-kexec.bash;
}
