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
    boot.cleanTmpDir = mkDefault true;

    networking.useDHCP = mkForce false;

    nix.package = pkgs.nixUnstable;
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
    nix.binaryCaches = [ "https://cache.jmbaur.com/" ];
    nix.binaryCachePublicKeys = [ "cache.jmbaur.com:Zw4UQwDtZLWHgNrgKiwIyMDWsBVLvtDMg3zcebvgG8c=" ];

    nix.gc.automatic = mkDefault true;
    nix.gc.dates = mkDefault "weekly";

    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.layout = "us";
    services.xserver.xkbModel = "pc104";
    services.xserver.xkbVariant = "qwerty";
    services.xserver.xkbOptions = "ctrl:nocaps";
    console = {
      earlySetup = true;
      font = "ter-v24n";
      useXkbConfig = true;
      packages = [ pkgs.terminus_font ];
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
