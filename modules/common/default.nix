{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
  isNotContainer = !config.boot.isContainer;
in
with lib;
{
  options = {
    custom.common.enable = mkEnableOption "Enable common options";
  };

  config = mkIf cfg.enable {

    users.mutableUsers = mkDefault false;

    boot = mkIf isNotContainer {
      cleanTmpDir = mkDefault true;
      loader.grub.configurationLimit = mkDefault 50;
      loader.systemd-boot.configurationLimit = mkDefault 50;
    };

    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      gc = mkIf isNotContainer {
        automatic = mkDefault true;
        dates = mkDefault "weekly";
      };
    };

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      earlySetup = true;
      useXkbConfig = true;
    };
    services.xserver.xkbOptions = "ctrl:nocaps";

    environment.variables.EDITOR = "vim";
    environment.binsh = "${pkgs.dash}/bin/dash";
    environment.systemPackages = with pkgs; [
      bc
      bind
      curl
      dmidecode
      dnsutils
      file
      gitMinimal
      htop
      iputils
      killall
      lm_sensors
      lsof
      pciutils
      tcpdump
      tmux
      traceroute
      usbutils
      vim
    ];

    programs.bash = {
      loginShellInit = ''
        tmux new-session -d -s default -c "$HOME" 2>/dev/null || true
      '';
      interactiveShellInit = mkIf (!config.custom.gui.enable) ''
        if [ -z "$TMUX" ]; then
          tmux attach-session -t default
        fi
      '';
    };

    programs.tmux = {
      enable = true;
      terminal = "screen-256color";
      clock24 = true;
      baseIndex = 1;
      keyMode = "vi";
      extraConfig = ''
        set-option -g lock-command ${pkgs.vlock}/bin/vlock
        set-option -g lock-after-time 3600
        bind-key C-l lock-session
      '';
    };
  };

}
