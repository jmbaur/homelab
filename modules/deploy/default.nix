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
    nix.settings.trusted-users = [ "deploy" ];
    security.sudo = {
      enable = mkForce true;
      wheelNeedsPassword = mkForce false;
    };
    services.openssh.enable = mkForce true;
    services.openssh.passwordAuthentication = mkForce false;
    users = {
      mutableUsers = mkForce false;
      users.deploy = {
        isNormalUser = true;
        extraGroups = lib.singleton "wheel";
        openssh.authorizedKeys.keys = (import ../../data/asparagus-ssh-keys.nix);
        openssh.authorizedKeys.keyFiles = singleton (import ../../data/jmbaur-ssh-keys.nix);
      };
    };
  };
}
