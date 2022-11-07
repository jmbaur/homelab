{ config, lib, pkgs, systemConfig, ... }:
let
  cfg = config.custom.common;
in
with lib; {
  options.custom.common = {
    enable = mkOption {
      type = types.bool;
      default = systemConfig.custom.common.enable;
    };
  };
  config = mkIf cfg.enable {
    home.stateVersion = systemConfig.system.stateVersion;

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
