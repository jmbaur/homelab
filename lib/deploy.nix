{ lib, ... }: {
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
      openssh.authorizedKeys.keyFiles = lib.singleton (import ./ssh-keys.nix);
    };
  };
}
