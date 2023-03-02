{ config, lib, pkgs, ... }:
let
  cfg = config.custom.common;
  isNotContainer = !config.boot.isContainer;
in
with lib; {
  options.custom.common.enable = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Options that are generic to all nixos machines.
    '';
  };

  config = mkIf cfg.enable {
    users.mutableUsers = mkDefault false;

    boot.cleanTmpDir = mkDefault isNotContainer;
    boot.loader.grub.configurationLimit = mkDefault 50;
    boot.loader.systemd-boot.configurationLimit = mkDefault 50;

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;

    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" "repl-flake" ];
        trusted-users = [ "@wheel" ];
      };
      gc = mkIf isNotContainer {
        automatic = mkDefault true;
        dates = mkDefault "weekly";
      };
    };

    services.openssh = mkIf isNotContainer {
      enable = true;
      settings = {
        PermitRootLogin = mkDefault "prohibit-password";
        PasswordAuthentication = mkDefault false;
      };
    };

    environment.variables.XKB_DEFAULT_OPTIONS = config.services.xserver.xkbOptions;

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
        set-option -g detach-on-destroy off
        set-option -g focus-events on
        set-option -g renumber-windows on
        set-option -g set-clipboard on
        set-option -g set-titles on
        set-option -g set-titles-string "#T"
        set-option -g status-style bg=#222222
        set-option -sa terminal-overrides ',xterm-256color:RGB'
      '';
    };
  };
}
