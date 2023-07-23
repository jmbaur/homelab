{ config, pkgs, lib, ... }:
let
  cfg = config.custom.installer;
in
{
  options.custom.installer.enable = lib.mkEnableOption "installer";
  config = lib.mkIf cfg.enable {
    system.stateVersion = "23.11";

    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_6_1;
    custom.disableZfs = true;
    programs.vim.defaultEditor = true;

    services.openssh.openFirewall = lib.mkForce true;
    systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

    services.getty.autologinUser = "root";
    users.users.root.initialHashedPassword = "";
    users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
  };
}
