{ config, lib, ... }: with lib; {
  imports = [ ./common.nix ]; # TODO(jared): delete me
  security.sudo = {
    enable = mkForce true;
    wheelNeedsPassword = mkForce false;
  };
  services.openssh.enable = mkForce true;
  users.users.deploy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "helloworld";
    openssh.authorizedKeys.keys = builtins.filter
      (str: builtins.stringLength str != 0)
      (lib.splitString "\n" (builtins.readFile ./ssh_keys.txt));
  };
}
