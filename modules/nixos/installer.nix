{ config, pkgs, lib, ... }:
let
  cfg = config.custom.installer;
in
{
  options.custom.installer.enable = lib.mkEnableOption "installer";
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ ];
    system.stateVersion = "22.11";
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    custom.disableZfs = true;
    systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
    users.users.nixos.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    console.useXkbConfig = true;
    services.xserver.xkbOptions = "ctrl:nocaps";
    programs.ssh.startAgent = true;
    programs.gnupg.agent.enable = true;
    nix = {
      package = pkgs.nixUnstable;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
    environment = {
      variables.EDITOR = lib.mkForce "nvim";
      systemPackages = with pkgs; [ curl git tmux neovim ];
    };
  };
}
