{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
in
{
  options.custom.common.enable = lib.mkEnableOption "Enable common configs";
  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    home.shellAliases = {
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
      speedtest-cli
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

    programs.htop = {
      enable = true;
      settings = {
        cpu_count_from_one = 0;
        highlight_base_name = 1;
      };
    };

    programs.dircolors.enable = true;
  };
}
