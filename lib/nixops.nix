{ lib, ... }:
with lib;
{
  nix.gc.automatic = mkDefault true;
  services.openssh.enable = mkDefault true;
  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ "${builtins.readFile ./yubikeySshKey.txt}" ];
}
