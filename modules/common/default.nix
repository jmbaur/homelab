{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
in
with lib;
{
  options = {
    custom.common.enable = mkEnableOption "Enable common options";
  };

  config = mkIf cfg.enable {
    boot = {
      cleanTmpDir = mkDefault true;
      loader.grub.configurationLimit = mkDefault 50;
      loader.systemd-boot.configurationLimit = mkDefault 50;
    };

    networking.useDHCP = mkForce false;

    nix.package = pkgs.nixFlakes;
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
    nix.settings = {
      substituters = [ "https://cache.jmbaur.com/" ];
      trusted-public-keys = [ "cache.jmbaur.com:Zw4UQwDtZLWHgNrgKiwIyMDWsBVLvtDMg3zcebvgG8c=" ];
    };

    nix.gc.automatic = mkDefault true;
    nix.gc.dates = mkDefault "weekly";

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;
    services.xserver = {
      layout = "us";
      xkbModel = "pc104";
      xkbVariant = "qwerty";
      xkbOptions = "ctrl:nocaps";
    };

    programs.mtr.enable = true;
    programs.traceroute.enable = true;

    environment.binsh = "${pkgs.dash}/bin/dash";
    environment.systemPackages = with pkgs; [
      acpi
      atop
      bc
      bind
      curl
      dmidecode
      dnsutils
      file
      htop
      iftop
      iperf3
      iputils
      killall
      lm_sensors
      nload
      nmap
      pciutils
      pfetch
      procs
      pstree
      tcpdump
      tmux
      traceroute
      tree
      usbutils
      vim
      w3m
      wget
    ];
  };

}
