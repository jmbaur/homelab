{ config, lib, pkgs, ... }:
let
  cfg = config.custom.deployee;
  hasEncryptedDrives = config.boot.initrd.luks.devices != { };
in
with lib;
{
  options = {
    custom.deployee.enable = mkEnableOption "Make this machine a deploy target";
  };

  config = mkIf cfg.enable {
    assertions = [
      # {
      #   assertion = hasEncryptedDrives && TODO (jared): search for network kernel modules in boot.initrd.availableKernelModules;
      #   message = "Must include kernel module for network card in boot.initrd.availableKernelModules option.";
      # }
    ];

    services.openssh = {
      enable = mkForce true;
      passwordAuthentication = mkForce false;
      permitRootLogin = "prohibit-password";
    };

    users.users.root.openssh.authorizedKeys = {
      keyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
        ../../data/asparagus-ssh-keys.txt
      ];
    };

    boot = mkIf hasEncryptedDrives {
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
