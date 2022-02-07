{ config, lib, ... }:
let
  cfg = config.custom.deploy;
in
with lib;
{
  options = { custom.deploy.enable = mkEnableOption "Make this machine a deploy target"; };

  config = mkIf cfg.enable {
    nix.trustedUsers = [ "deploy" ];
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
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = (import ../../data/manager-ssh-keys.nix);
        openssh.authorizedKeys.keyFiles = singleton (import ../../data/ssh-keys.nix);
      };
    };
  };
}
