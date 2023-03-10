{ config, pkgs, lib, ... }:
let
  cfg = config.custom.installer;
in
{
  options.custom.installer.enable = lib.mkEnableOption "installer";
  config = lib.mkIf cfg.enable {
    system.stateVersion = "23.05";
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_6_1;
    custom.disableZfs = true;
    systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
    users.users.nixos.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    services.openssh.openFirewall = lib.mkForce true;
    programs.ssh.startAgent = true;
    programs.gnupg.agent.enable = true;
    programs.vim.defaultEditor = true;
    environment.systemPackages = with pkgs; [ curl git tmux ];
  };
}