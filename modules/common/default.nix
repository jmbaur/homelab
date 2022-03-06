{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
  customVim = pkgs.vim_configurable.customize {
    name = "vim";
    vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
      start = [
        vim-eunuch
        vim-fugitive
        vim-lastplace
        vim-nix
        vim-rsi
        vim-sensible
      ];
      opt = [ ];
    };
    vimrcConfig.customRC = ''
      set hidden
      set number
      set relativenumber
    '';
  };
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

    nix = {
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      gc = {
        automatic = mkDefault true;
        dates = mkDefault "weekly";
      };
    };


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

    environment.variables.EDITOR = "vim";

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
      git
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
      w3m
      wget
    ] ++ [ customVim ];
  };

}
