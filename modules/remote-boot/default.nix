{ config, lib, pkgs, ... }:
let
  cfg = config.custom.remoteBoot;
in
with lib;
{
  options.custom.remoteBoot = {
    enable = mkOption {
      type = types.bool;
      default = (config.custom.deployee.enable) && (config.boot.initrd.luks.devices != { });
      description = ''
        Enable remote boot
      '';
    };
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The interface to use for autoconfiguration during stage-1 boot
      '';
    };
  };
  config = mkIf cfg.enable {
    assertions = [
      # {
      #   assertion = TODO(jared): search for network kernel modules in boot.initrd.availableKernelModules;
      #   message = "Must include kernel module for network card in boot.initrd.availableKernelModules option.";
      # }
    ];
    boot = {
      kernelParams = [
        (if cfg.interface == null then
          "ip=dhcp"
        else
          "ip=:::::${cfg.interface}:dhcp")
      ];
      initrd.network = {
        enable = true;
        postCommands = ''
          echo "cryptsetup-askpass; exit" > /root/.profile
        '';
        ssh = {
          enable = true;
          # TODO(jared): may need to create separate keys outside of what is
          # created from the openssh nixos module.
          hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ];
          authorizedKeys = (builtins.filter
            (key: key != "")
            (lib.splitString
              "\n"
              (builtins.readFile (import ../../data/jmbaur-ssh-keys.nix))
            )) ++ [ (builtins.readFile ../../data/deployer-ssh-keys.txt) ];
        };
      };
    };
  };
}
