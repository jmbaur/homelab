{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
in
with lib; {
  options.custom.common.enable = mkEnableOption "common configurations";
  config = mkIf cfg.enable {
    home.stateVersion = "22.11";

    nixpkgs.config.allowUnfree = true;

    home.shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };

    home.packages = with pkgs; [
      gmni
      iperf3
      librespeed-cli
      nmap
      nvme-cli
      picocom
      pwgen
      rtorrent
      sl
      smartmontools
      sshfs
      stow
      tailscale
      tcpdump
      tree
      unzip
      usbutils
      w3m
      wireguard-tools
      zip
    ];

    programs.dircolors.enable = true;
  };
}
