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
in
{
  options.custom.common.enable = mkEnableOption "common config";

  config = mkIf cfg.enable (mkMerge [
    {
      system.stateVersion = mkDefault "25.05";

      environment.systemPackages = [ pkgs.nixos-kexec ];

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

      # No need for mutable users in most use cases
      users.mutableUsers = mkDefault false;
      services.userborn.enable = mkDefault true;

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

      # Prevent copying in nixpkgs source eagerly
      nixpkgs.flake.source = mkForce null;

      # Provide a sane default value so that nix commands don't outright fail on
      # an otherwise unconfigured machine.
      nix.nixPath = mkDefault [
        "nixpkgs=https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz"
      ];

      # Use the dbus-broker dbus daemon implementation (more performance, yeah?)
      services.dbus.implementation = "broker";

      # The default max inotify watches is 8192. Nowadays most apps require a
      # good number of inotify watches, the value below is used by default on
      # several other distros.
      boot.kernel.sysctl = {
        "fs.inotify.max_user_instances" = 524288;
        "fs.inotify.max_user_watches" = 524288;
      };

      # MLS is deprecated (see https://github.com/NixOS/nixpkgs/issues/321121),
      # beacondb.net has been proposed as a successor.
      services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate";
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
