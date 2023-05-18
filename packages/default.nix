inputs: with inputs;
let
  commonDerivations = pkgs: {
    netboot-test = pkgs.symlinkJoin {
      name = "netboot-test";
      paths = with self.nixosConfigurations.netboot-test.config.system.build; [
        netbootRamdisk
        kernel
        netbootIpxeScript
      ];
      preferLocalBuild = true;
    };

    inherit (pkgs)
      bitwarden-bemenu
      chromium-wayland
      cicada
      coredns-utils
      depthcharge-tools
      flarectl
      flashrom-cros
      flashrom-dasharo
      git-get
      git-shell-commands
      gobar
      gosee
      grafana-dashboards
      ixio
      j
      jmbaur-github-ssh-keys
      jmbaur-keybase-pgp-keys
      kinesis-kint41-jmbaur
      macgen
      mirror-to-x
      neovim
      neovim-all-languages
      pd-notify
      pomo
      stevenblack-blocklist
      u-rootInitramfs
      v4l-show
      wip
      xremap
      yamlfmt
      ;

  };
in
{
  armv7l-linux =
    let
      pkgs = import nixpkgs {
        system = "armv7l-linux";
        overlays = [ self.overlays.default ];
      };
    in
    {
      inherit (pkgs)
        ubootClearfog
        ubootClearfogSpi
        ubootClearfogUart
        ;
    };

  aarch64-linux =
    let
      pkgs = import nixpkgs {
        system = "aarch64-linux";
        overlays = [
          gobar.overlays.default
          gosee.overlays.default
          ipwatch.overlays.default
          pd-notify.overlays.default
          runner-nix.overlays.default
          self.overlays.default
          tinyboot.overlays.default
          webauthn-tiny.overlays.default
        ];
      };
    in
    pkgs.lib.recursiveUpdate (commonDerivations pkgs) {
      inherit (pkgs)
        # linux_orangepi-5
        ubootCN9130_CF_Pro
        ;
    };

  x86_64-linux =
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          gobar.overlays.default
          gosee.overlays.default
          ipwatch.overlays.default
          pd-notify.overlays.default
          runner-nix.overlays.default
          self.overlays.default
          tinyboot.overlays.default
          webauthn-tiny.overlays.default
        ];
      };
    in
    pkgs.lib.recursiveUpdate (commonDerivations pkgs) {
      beetroot-firmware = pkgs.coreboot.volteer-elemi.override {
        config.tinyboot.verifiedBoot = {
          enable = true;
          publicKey = ../nixos-configurations/beetroot/tinyboot-pubkey.pem;
        };
      };
    };
}
