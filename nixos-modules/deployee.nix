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

    # We don't need nixos-rebuild on a machine that gets remote deployments.
    system.disableInstallerTools = true;

    system.build.deploy = pkgs.pkgsBuildBuild.callPackage
      ({ writeShellApplication, openssh }: writeShellApplication {
        name = "deploy";
        runtimeInputs = [ openssh ];
        text = ''
          deploy_type=''${1:-switch}
          target=''${SSHTARGET:-${cfg.sshTarget}}

          # shellcheck disable=SC2086
          nix copy ''${NIXCOPYOPTS:-} --to "ssh-ng://''${target}" ${config.system.build.toplevel}

          # shellcheck disable=SC2086
          ssh ''${SSHOPTS:-} "$target" \
            nix-env --profile /nix/var/nix/profiles/system --set ${config.system.build.toplevel}

          # using systemd-run during switch-to-configuration: https://github.com/NixOS/nixpkgs/pull/258571
          # shellcheck disable=SC2029,SC2086
          ssh ''${SSHOPTS:-} "$target" \
            systemd-run \
              -E LOCALE_ARCHIVE \
              -E NIXOS_INSTALL_BOOTLOADER \
              --collect \
              --no-ask-password \
              --pty \
              --quiet \
              --same-dir \
              --service-type=exec \
              --unit=nixos-rebuild-switch-to-configuration \
              --wait \
              ${config.system.build.toplevel}/bin/switch-to-configuration "$deploy_type"

          if [[ "$deploy_type" == "boot" ]]; then
            echo "system set to switch to new configuration at next boot, reboot to see changes"
          fi
        '';
      })
      { };
  };
}
