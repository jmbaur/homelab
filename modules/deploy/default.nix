{ config, lib, pkgs, ... }:
let
  cfg = config.custom.deploy;
in
with lib;
{
  options = {
    custom.deploy.enable = mkEnableOption "Make this machine a deploy target";
  };

  config = mkIf cfg.enable {
    services.openssh.enable = mkForce true;
    services.openssh.passwordAuthentication = mkForce false;
    users.users.root.openssh.authorizedKeys.keys = (import ../../data/rhubarb-ssh-keys.nix);
    users.users.root.openssh.authorizedKeys.keyFiles = singleton (import ../../data/jmbaur-ssh-keys.nix); # backup


    # TODO(jared): Consider forcing configuration of a kernel module for
    # network card to load during initrd phase.
    boot = mkIf (config.boot.initrd.luks.devices != { }) {
      kernelParams = [ "ip=dhcp" ];
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
          authorizedKeys = builtins.filter
            (key: key != "")
            (lib.splitString
              "\n"
              (builtins.readFile (import ../../data/jmbaur-ssh-keys.nix))
            );
        };
      };
    };
  };
}
