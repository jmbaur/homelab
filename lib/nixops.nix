{ lib, ... }:
with lib;
{
  imports = [ ./common.nix ];
  security.sudo.enable = mkDefault false;
  services.openssh.enable = mkDefault true;
  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ "${builtins.readFile ./yubikeySshKey.txt}" ];
}
