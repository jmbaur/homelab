{ config, pkgs, ... }:
{
  services.openssh.enable = true;
  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ "${builtins.readFile ./desktopSshKey.txt}" "${builtins.readFile ./yubikeySshKey.txt}" ];
}
