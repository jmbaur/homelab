{ config, lib, pkgs, ... }:
with lib;
{
  boot = {
    tmpOnTmpfs = mkDefault true;
    cleanTmpDir = mkDefault true;
  };

  nix.gc.automatic = mkDefault true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    earlySetup = true;
    font = "ter-v24n";
    keyMap = "us";
    packages = [ pkgs.terminus_font ];
  };

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
    tmux
    traceroute
    tree
    vim
    w3m
    wget
  ];
}
