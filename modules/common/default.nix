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
      package = pkgs.nixUnstable;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      gc = mkIf isNotContainer {
        automatic = mkDefault true;
        dates = mkDefault "weekly";
      };
    };

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;
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
      mullvad
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
    };

    services.physlock.enable = !config.custom.gui.enable;

    programs.tmux = {
      enable = true;
      terminal = "screen-256color";
      clock24 = true;
      baseIndex = 1;
      keyMode = "vi";
    };
  };

}
