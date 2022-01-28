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
      enable = lib.mkForce true;
      wheelNeedsPassword = lib.mkForce false;
    };
    services.openssh.enable = lib.mkForce true;
    users = {
      mutableUsers = lib.mkForce false;
      users.deploy = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keyFiles = lib.singleton (import ../../lib/ssh-keys.nix);
      };
    };
  };
}
