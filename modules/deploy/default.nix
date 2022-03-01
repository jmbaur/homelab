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
    users.users.root.openssh.authorizedKeys.keys = (import ../../data/asparagus-ssh-keys.nix);
    users.users.root.openssh.authorizedKeys.keyFiles = singleton (import ../../data/jmbaur-ssh-keys.nix);
  };
}
