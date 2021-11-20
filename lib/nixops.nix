{ lib, ... }:
with lib;
{
  services.openssh.enable = mkDefault true;
  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ "${builtins.readFile ./yubikeySshKey.txt}" ];
}
