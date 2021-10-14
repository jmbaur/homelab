{ config, pkgs, ... }:
{
  services.openssh.enable = true;
  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ "${builtins.readFile ./publicSSHKey.txt}" ];
}
