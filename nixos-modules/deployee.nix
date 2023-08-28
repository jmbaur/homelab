{ config, lib, pkgs, ... }:
let
  cfg = config.custom.deployee;
in
with lib;
{
  options.custom.deployee = {
    enable = mkEnableOption "deploy target";
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    authorizedKeyFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
    };
    sshTarget = lib.mkOption { type = lib.types.str; };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = (cfg.authorizedKeyFiles != [ ] || cfg.authorizedKeys != [ ]);
      message = "No authorized keys configured for deployee";
    }];

    services.openssh = {
      enable = true;
      listenAddresses = [ ]; # this defaults to all addresses
    };

    users.users.root.openssh.authorizedKeys = {
      keys = cfg.authorizedKeys;
      keyFiles = cfg.authorizedKeyFiles;
    };

    system.build.deploy = pkgs.buildPackages.writeShellScriptBin "deploy" ''
      set -e

      deploy_type=''${1:-switch}
      target=''${SSHTARGET:-${cfg.sshTarget}}

      nix copy $NIXCOPYOPTS --to ssh-ng://$target ${config.system.build.toplevel}
      ssh $SSHOPTS $target \
        nix-env --profile /nix/var/nix/profiles/system --set ${config.system.build.toplevel}
      ssh $SSHOPTS $target \
        ${config.system.build.toplevel}/bin/switch-to-configuration "$deploy_type"
      if [[ "$deploy_type" == "boot" ]]; then
        echo "system set to switch to new configuration at next boot, reboot to see changes"
      fi
    '';
  };
}
