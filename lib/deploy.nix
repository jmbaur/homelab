{ config, lib, ... }: with lib; {
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
      openssh.authorizedKeys.keys = builtins.filter
        (str: builtins.stringLength str != 0)
        (lib.splitString "\n" (builtins.readFile ./ssh_keys.txt));
    };
  };
}
