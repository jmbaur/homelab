{ config, lib, ... }: {
  nix.trustedUsers = [ "deploy" ];
  security.sudo = {
    enable = mkForce true;
    wheelNeedsPassword = mkForce false;
  };
  services.openssh.enable = mkForce true;
  users = {
    mutableUsers = mkForce false;
    users.deploy = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keyFiles = lib.singleton (import ./sshKeys.nix);
    };
  };
}
