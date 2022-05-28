{ config, lib, pkgs, ... }:
let
  cfg = config.custom.deployee;
  hasEncryptedDrives = config.boot.initrd.luks.devices != { };
in
with lib;
{
  options.custom.deployee.enable = mkEnableOption "Make this machine a deploy target";

  config = mkIf cfg.enable {
    services.openssh = {
      enable = mkForce true;
      passwordAuthentication = mkForce false;
      permitRootLogin = "prohibit-password";
    };

    users.users.root.openssh.authorizedKeys = {
      keyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
        ../../data/deployer-ssh-keys.txt
      ];
    };
  };
}
