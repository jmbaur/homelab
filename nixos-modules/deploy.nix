{ config, pkgs, ... }: {
  system.build.deploy = pkgs.writeShellScriptBin "deploy" ''
    ssh_target=$1
    deploy_type=''${2:-switch}
    nix-copy-closure --to $ssh_target ${config.system.build.toplevel}
    ssh $ssh_target ${config.system.build.toplevel}/bin/switch-to-configuration $deploy_type
  '';
}
