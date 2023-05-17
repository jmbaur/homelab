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
    environment.systemPackages = [ pkgs.nixos-kexec ];

    security.sudo.extraRules = [{ groups = [ "wheel" ]; commands = [{ command = "/run/current-system/sw/bin/networkctl"; options = [ "NOPASSWD" ]; }]; }];

    users.mutableUsers = mkDefault false;

    networking.nftables.enable = mkDefault true;

    boot.tmp.cleanOnBoot = mkDefault isNotContainer;
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
      openFirewall = false;
      settings = {
        PermitRootLogin = mkDefault "prohibit-password";
        PasswordAuthentication = mkDefault false;
      };
    };

    environment.sessionVariables.XKB_DEFAULT_OPTIONS = config.services.xserver.xkbOptions;
    environment.sessionVariables.XKB_DEFAULT_MODEL = config.services.xserver.xkbModel;
    environment.sessionVariables.XKB_DEFAULT_VARIANT = config.services.xserver.xkbVariant;

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
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection
        bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
        set-option -g allow-passthrough on
        set-option -g automatic-rename on
        set-option -g detach-on-destroy off
        set-option -g focus-events on
        set-option -g renumber-windows on
        set-option -g set-clipboard on
        set-option -g set-titles on
        set-option -g set-titles-string "#T"
        set-option -g status-left ""
        set-option -g status-right "#S"
        set-option -sa terminal-overrides ',xterm-256color:RGB'
      '';
    };
  };
}
