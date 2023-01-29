{ config, lib, ... }:
let
  cfg = config.custom.remoteBoot;
in
with lib; {
  options.custom.remoteBoot = {
    enable = mkOption {
      type = types.bool;
      default = config.custom.deployee.enable && (config.boot.initrd.luks.devices != { });
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
    authorizedKeyFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
    };
  };
  config = mkIf cfg.enable {
    assertions = [{
      assertion = config.services.openssh.enable;
      message = "OpenSSH must be enabled on host";
    }];
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
          hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ];
          authorizedKeys = lib.flatten (map
            (file:
              (builtins.filter
                (content: content != "")
                (lib.splitString "\n" (builtins.readFile file))
              ))
            cfg.authorizedKeyFiles);
        };
      };
    };
  };
}
