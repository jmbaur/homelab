{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    genAttrs
    mkDefault
    mkEnableOption
    mkIf
    ;

  cfg = config.custom.common;

  isNotContainer = !config.boot.isContainer;
in
{
  options.custom.common = {
    enable = mkEnableOption "common config";

    # Add a way to opt-out of cross-compiled nixos machines :/
    nativeBuild = mkEnableOption "enable native building";
  };

  config = mkIf cfg.enable {
    system.stateVersion = mkDefault "25.05";

    # We always build on x86_64-linux.
    #
    # "If it don't cross-compile, it don't go in the config!"
    nixpkgs.buildPlatform = mkIf (!cfg.nativeBuild) "x86_64-linux";

    # CapsLock is terrible
    services.xserver.xkb.options = mkDefault "ctrl:nocaps";

    boot.initrd.systemd.enable = mkDefault true;
    system.etc.overlay.enable = mkDefault true;

    environment.enableAllTerminfo = mkDefault true;

    programs.nano.enable = mkDefault false;
    programs.vim = {
      enable = mkDefault true;
      defaultEditor = true;
      package = pkgs.vim.customize {
        vimrcFile = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/archlinux/svntogit-packages/68f6d131750aa778807119e03eed70286a17b1cb/trunk/archlinux.vim";
          hash = "sha256-DPi0JzIRHQxmw5CKdtgyc26PjcOr74HLCS3fhMuGLqI=";
        };
        standalone = true; # prevents desktop entries from showing up
      };
    };

    # moving closer to perlless system
    environment.defaultPackages = mkDefault [ ];
    documentation.info.enable = mkDefault false;
    programs.command-not-found.enable = mkDefault false;
    boot.enableContainers = mkDefault false;

    networking.nftables.enable = mkDefault true;

    boot.tmp.cleanOnBoot = mkDefault isNotContainer;

    # The initrd doesn't have a fully-functioning terminal, prevent systemd
    # from using pager for services that launch a shell
    boot.initrd.systemd.services =
      genAttrs
        [
          "emergency"
          "rescue"
        ]
        (_: {
          environment.SYSTEMD_PAGER = "cat";
        });

    environment.stub-ld.enable = false;

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;

    # no need for mutable users
    users.mutableUsers = mkDefault false;
    systemd.sysusers.enable = mkDefault true;

    programs.tmux = {
      enable = mkDefault true;
      keyMode = mkIf (config.programs.vim.enable || config.programs.neovim.enable) "vi";
    };

    nix = {
      package = pkgs.nixVersions.nix_2_25;
      channel.enable = false; # opt out of nix channels
      distributedBuilds = true; # allow for populating /etc/nix/machines for remote building
      settings = {
        auto-allocate-uids = true;
        sync-before-registering = true;
        trusted-users = [ "@wheel" ];
        experimental-features = [
          "auto-allocate-uids"
          "flakes"
          "nix-command"
        ];
      };
    };

    # Provide a sane default value so that nix commands don't outright fail on
    # an otherwise unconfigured machine.
    environment.sessionVariables.NIX_PATH = mkIf config.nix.enable (
      mkDefault "nixpkgs=https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz"
    );

    # Use the dbus-broker dbus daemon implementation (more performance, yeah?)
    services.dbus.implementation = "broker";

    services.openssh = {
      enable = mkDefault isNotContainer;
      settings.PasswordAuthentication = false;
    };

    # The default max inotify watches is 8192. Nowadays most apps require a
    # good number of inotify watches, the value below is used by default on
    # several other distros.
    boot.kernel.sysctl = {
      "fs.inotify.max_user_instances" = 524288;
      "fs.inotify.max_user_watches" = 524288;
    };

    # MLS is deprecated: https://github.com/NixOS/nixpkgs/issues/321121
    #
    # NOTE: This is for personal usage only (and has very low limits), be a
    # good person and get your own API key.
    services.geoclue2.geoProviderUrl =
      "https://www.googleapis.com/geolocation/v1/geolocate?key="
      + "A"
      + "I"
      + "z"
      + "a"
      + "S"
      + "y"
      + "A"
      + "_"
      + "W"
      + "j"
      + "R"
      + "8"
      + "4"
      + "L"
      + "S"
      + "r"
      + "J"
      + "r"
      + "t"
      + "R"
      + "L"
      + "a"
      + "S"
      + "I"
      + "j"
      + "G"
      + "-"
      + "Q"
      + "f"
      + "n"
      + "s"
      + "c"
      + "N"
      + "c"
      + "v"
      + "3"
      + "P"
      + "y"
      + "Y";
  };
}
