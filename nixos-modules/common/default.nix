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
    mkForce
    mkIf
    mkMerge
    ;

  cfg = config.custom.common;

  isNotContainer = !config.boot.isContainer;

  inherit (config.system.nixos) revision;
in
{
  options.custom.common.enable = mkEnableOption "common config";

  config = mkIf cfg.enable (mkMerge [
    {
      system.stateVersion = mkDefault "25.11";

      environment.systemPackages = [
        pkgs.modprobed-db
        pkgs.nixos-kexec
      ];

      boot.initrd.systemd.enable = mkDefault true;
      system.etc.overlay.enable = mkDefault true;

      # Maximum terminal compatibility for ssh sessions.
      environment.enableAllTerminfo = mkDefault config.services.openssh.enable;

      # moving closer to perlless system
      environment.defaultPackages = mkDefault [ ];
      documentation.info.enable = mkDefault false;
      programs.command-not-found.enable = mkDefault false;
      boot.enableContainers = mkDefault false;

      programs.nano.enable = false;
      programs.vim = lib.mkIf (!(config.programs.neovim.enable && config.programs.neovim.defaultEditor)) {
        enable = true;
        defaultEditor = true;
      };

      networking.useDHCP = false;
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

      # No need for mutable users in most use cases
      users.mutableUsers = mkDefault false;
      services.userborn.enable = mkDefault true;

      nix = {
        package = pkgs.nixVersions.nix_2_32;
        channel.enable = false; # opt out of nix channels
        distributedBuilds = mkDefault true; # allow for populating /etc/nix/machines for remote building
        settings = {
          allow-import-from-derivation = false;
          auto-allocate-uids = true;
          builders-use-substitutes = mkDefault true;
          fsync-store-paths = true;
          use-cgroups = true;
          extra-trusted-users = [ "@wheel" ];
          extra-system-features = [ "uid-range" ];
          extra-experimental-features = [
            "auto-allocate-uids"
            "cgroups"
            "flakes"
            "nix-command"
            "no-url-literals"
          ];
        };
      };

      # Entirely unhelpful tool when the nixos config is not shipped on the
      # device.
      system.tools.nixos-option.enable = mkDefault false;

      # Prevent copying in nixpkgs source eagerly
      nixpkgs.flake.source = mkForce null;

      # Provide a sane default value so that nix commands don't outright fail on
      # an otherwise unconfigured machine.
      nix.nixPath = mkDefault [
        "nixpkgs=https://github.com/nixos/nixpkgs/archive/${
          if (revision != null) then revision else "nixos-unstable"
        }.tar.gz"
      ];

      # TODO(jared): Can delete this after e51ab12e173e3699bb5c0fbe9985e5231d6729a4 is in nixos-unstable.
      services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate";
    }

    {
      # bcache-tools doesn't cross-compile, and this is enabled by default??
      boot.bcache.enable = mkDefault false;
    }

    # Performance related
    {
      # Use the dbus-broker dbus daemon implementation (more performance, yeah?)
      services.dbus.implementation = "broker";

      # TODO(jared): can remove once https://github.com/NixOS/nixpkgs/pull/417511 is in nixos-unstable.
      #
      # The default max inotify watches is 8192. Nowadays most apps require a
      # good number of inotify watches, the value below is used by default on
      # several other distros.
      boot.kernel.sysctl = {
        "fs.inotify.max_user_instances" = 524288;
        "fs.inotify.max_user_watches" = 524288;
      };

      hardware.block.scheduler = mkDefault {
        "mmcblk[0-9]*" = "bfq";
        "sd[a-z][0-9]*" = "bfq";
        "nvme[0-9]*" = "mq-deadline";
      };

      boot.kernelParams = [
        "systemd.show_status=auto"
        "systemd.log_level=warning"
      ];
    }

    {
      services.openssh = {
        enable = mkDefault isNotContainer;
        settings.PasswordAuthentication = false;
      };
    }
  ]);
}
