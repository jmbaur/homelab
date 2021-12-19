{ config, lib, ... }:
with lib;
{
  imports = [ ./common.nix ];
  security.sudo.enable = mkDefault false;
  services.openssh.enable = mkDefault true;
  users.extraUsers.root.openssh.authorizedKeys.keys = mkIf config.services.openssh.enable (
    builtins.filter
      (str: builtins.stringLength str != 0)
      (lib.splitString "\n" (builtins.readFile ./ssh_keys.txt))
  );
}
