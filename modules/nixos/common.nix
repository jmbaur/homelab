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

    fonts.fontconfig.enable = mkDefault false;
    documentation.enable = mkDefault false;
    documentation.man.enable = mkDefault false;
    documentation.info.enable = mkDefault false;

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

    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      escapeTime = 10;
      keyMode = "vi";
      plugins = with pkgs.tmuxPlugins; [ logging ];
      terminal = "tmux-256color";
      extraConfig = ''
        bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
        set-option -g allow-passthrough on
        set-option -g automatic-rename on
        set-option -g focus-events on
        set-option -g renumber-windows on
        set-option -g set-clipboard on
        set-option -g set-titles on
        set-option -g set-titles-string "#T"
        set-option -sa terminal-overrides ',xterm-256color:RGB'
      '';
    };
  };
}
