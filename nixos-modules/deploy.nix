{ config, pkgs, ... }: {
  system.build.deploy = pkgs.writeShellScriptBin "deploy" ''
    ssh_target=$1
    deploy_type=''${2:-switch}
    nix-copy-closure --to $ssh_target ${config.system.build.toplevel}
    ssh $SSHOPTS $ssh_target nix-env --profile /nix/var/nix/profiles/system --set ${config.system.build.toplevel}
    ssh $SSHOPTS $ssh_target ${config.system.build.toplevel}/bin/switch-to-configuration "$deploy_type"
    if [[ "$deploy_type" == "boot" ]]; then
      echo "system set to switch to new configuration at next boot, reboot to see changes"
    fi
  '';
}
