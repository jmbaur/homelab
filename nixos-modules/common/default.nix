{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.common;
  isNotContainer = !config.boot.isContainer;
in
{
  options.custom.common.enable = lib.mkEnableOption "common config" // {
    default = true;
  };

  # Add a way to opt-out of cross-compiled nixos machines :/
  options.custom.nativeBuild = lib.mkEnableOption "enable native building";

  config = lib.mkIf cfg.enable {
    system.stateVersion = lib.mkDefault "25.05";

    system.image.id = config.system.nixos.distroId;

    # We always build on x86_64-linux.
    #
    # "If it don't cross-compile, it don't go in the config!"
    nixpkgs.buildPlatform = lib.mkIf (!config.custom.nativeBuild) "x86_64-linux";

    # CapsLock is terrible
    services.xserver.xkb.options = lib.mkDefault "ctrl:nocaps";

    environment.enableAllTerminfo = true;

    programs.nano.enable = false;
    programs.vim = {
      enable = true;
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
    environment.defaultPackages = lib.mkDefault [ ];
    documentation.info.enable = lib.mkDefault false;
    programs.command-not-found.enable = false;
    boot.enableContainers = lib.mkDefault false;

    networking.nftables.enable = lib.mkDefault true;

    boot.tmp.cleanOnBoot = lib.mkDefault isNotContainer;

    # The initrd doesn't have a fully-functioning terminal, prevent systemd
    # from using pager for services that launch a shell
    boot.initrd.systemd.services =
      lib.genAttrs
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
    users.mutableUsers = lib.mkDefault false;
    systemd.sysusers.enable = lib.mkDefault true;

    programs.tmux = {
      enable = true;
      keyMode = lib.mkIf (config.programs.vim.enable || config.programs.neovim.enable) "vi";
    };

    nix = {
      package = pkgs.nixVersions.nix_2_25_sysroot;
      channel.enable = false; # opt out of nix channels
      distributedBuilds = true;
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

    # Provide a sane default value so that commands don't outright fail on an
    # otherwise unconfigured machine.
    environment.sessionVariables.NIX_PATH = lib.mkIf config.nix.enable (
      lib.mkDefault "nixpkgs=https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz"
    );

    # Use the dbus-broker dbus daemon implementation (more performance, yeah?)
    services.dbus.implementation = "broker";

    services.openssh = {
      enable = lib.mkDefault isNotContainer;
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
