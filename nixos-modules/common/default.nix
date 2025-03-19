{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    genAttrs
    mkAfter
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
      system.stateVersion = mkDefault "25.05";

      environment.systemPackages = [ pkgs.nixos-kexec ];

      boot.initrd.systemd.enable = mkDefault true;
      system.etc.overlay.enable = mkDefault true;

      # Maximum terminal compatibility for ssh sessions.
      environment.enableAllTerminfo = mkDefault true;

      programs.nano.enable = mkDefault false;
      programs.vim = {
        enable = mkDefault true;
        defaultEditor = true;
        # Minimize the closure of vim
        package =
          (pkgs.vim-full.override {
            features = "huge"; # One of tiny, small, normal, big or huge
            config.vim = {
              gui = "none";
              python = false;
              lua = false;
              perl = false;
              tcl = false;
              ruby = false;
            };
          }).overrideAttrs
            (old: {
              postFixup =
                (old.postFixup or "")
                + ''
                  rm -rf $out/share/applications
                '';
            });

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

      # No need for mutable users in most use cases
      users.mutableUsers = mkDefault false;
      services.userborn.enable = mkDefault true;

      programs.tmux = {
        enable = mkDefault true;
        keyMode = mkIf (config.programs.vim.enable || config.programs.neovim.enable) "vi";
      };

      nix = {
        channel.enable = false; # opt out of nix channels
        distributedBuilds = mkDefault true; # allow for populating /etc/nix/machines for remote building
        settings = {
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

      # MLS is deprecated (see https://github.com/NixOS/nixpkgs/issues/321121),
      # beacondb.net has been proposed as a successor.
      services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate";
    }

    # Performance related
    {
      # Use the dbus-broker dbus daemon implementation (more performance, yeah?)
      services.dbus.implementation = "broker";

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
    }

    {
      services.openssh = {
        enable = mkDefault isNotContainer;
        openFirewall = mkDefault false;
        settings.PasswordAuthentication = false;
      };

      # Only open firewall for ssh on link-local ipv6. This ensures that we
      # cannot accidentally route ssh traffic over multiple networks, enforcing
      # this type of traffic to come from a machine on the same link.
      networking.firewall.extraInputRules =
        mkIf (with config.services.openssh; enable && !openFirewall)
          # Use mkAfter so that we can put other rules in the same input-allow
          # chain that will take precedence over this rule.
          (
            mkAfter ''
              ip6 saddr fe80::/64 tcp dport ssh accept
            ''
          );
    }
  ]);
}
