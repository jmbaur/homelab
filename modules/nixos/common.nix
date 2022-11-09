{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
  isNotContainer = !config.boot.isContainer;
in
with lib;
{
  options.custom.common.enable = mkEnableOption "common options";

  config = mkIf cfg.enable {
    users.mutableUsers = mkDefault false;

    boot = mkIf isNotContainer {
      cleanTmpDir = mkDefault true;
      loader.grub.configurationLimit = mkDefault 50;
      loader.systemd-boot.configurationLimit = mkDefault 50;
    };

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;
    services.xserver.xkbOptions = "ctrl:nocaps";

    fonts.fontconfig.enable = lib.mkDefault false;
    documentation.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    documentation.info.enable = lib.mkDefault false;

    nix = {
      nixPath = mkForce [ "nixpkgs=${pkgs.path}" ];
      settings.trusted-users = [ "@wheel" ];
      gc = mkIf isNotContainer {
        automatic = mkDefault true;
        dates = mkDefault "weekly";
      };
      extraOptions = ''
        experimental-features = nix-command flakes repl-flake
      '';
    };

    services.openssh = mkIf isNotContainer {
      enable = true;
      passwordAuthentication = mkDefault false;
      permitRootLogin = mkDefault "prohibit-password";
    };

    environment = {
      variables = {
        EDITOR = "vi";
        VISUAL = "vi";
        XKB_DEFAULT_OPTIONS = config.services.xserver.xkbOptions;
      };
      systemPackages = with pkgs; [
        bc
        curl
        dig
        dmidecode
        dnsutils
        file
        git
        htop
        iputils
        killall
        lm_sensors
        lsof
        nvi
        pciutils
        tcpdump
        traceroute
        usbutils
      ];
    };

    programs.tmux = import ../shared/tmux.nix;
  };
}
