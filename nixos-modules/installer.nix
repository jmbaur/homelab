{ config, pkgs, lib, ... }:
let
  cfg = config.custom.installer;
in
{
  options.custom.installer.enable = lib.mkEnableOption "installer";

  config = lib.mkIf cfg.enable {
    custom.disableZfs = true;
    programs.vim.defaultEditor = true;

    services.openssh.openFirewall = lib.mkForce true;
    systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

    services.getty.autologinUser = "root";
    users.users.root.initialHashedPassword = "";
    users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];
  };
}
