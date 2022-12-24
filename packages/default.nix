inputs: with inputs;
let
  commonDerivations = pkgs: {
    installer_iso = self.nixosConfigurations."installer_iso_${pkgs.system}".config.system.build.isoImage;

    router-test = pkgs.callPackage ../nixosModules/router/test.nix {
      module = self.nixosModules.router;
    };

    netboot-test = pkgs.symlinkJoin {
      name = "netboot-test";
      paths = with self.nixosConfigurations.netboot-test.config.system.build; [
        netbootRamdisk
        kernel
        netbootIpxeScript
      ];
      preferLocalBuild = true;
    };

    coreboot-toolchain-i386 = pkgs.coreboot-toolchain.i386.override { withAda = false; };
    coreboot-toolchain-aarch64 = pkgs.coreboot-toolchain.aarch64.override { withAda = false; };

    inherit (pkgs)
      bitwarden-bemenu
      chromium-wayland
      cicada
      coredns-utils
      depthcharge-tools
      discord-webapp
      edk2-uefi-coreboot-payload
      flarectl
      flashrom-cros
      git-get
      gobar
      gosee
      grafana-dashboards
      ixio
      j
      jmbaur-github-ssh-keys
      jmbaur-keybase-pgp-keys
      linux_linuxboot
      macgen
      mirror-to-x
      neovim
      neovim-image
      outlook-webapp
      pd-notify
      pomo
      slack-webapp
      spotify-webapp
      stevenblack-hosts
      teams-webapp
      u-rootInitramfs
      v4l-show
      wip
      xremap
      yamlfmt
      zf
      ;

  };
in
{
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
          webauthn-tiny.overlays.default
          self.overlays.default
        ];
      };
    in
    pkgs.lib.recursiveUpdate (commonDerivations pkgs) {
      inherit (pkgs)
        coreboot-asurada-spherion
        coreboot-kukui-fennel14
        coreboot-qemu-aarch64
        linux_mediatek
        linux_cn913x
        ubootCN9130_CF_Pro
        ;

      installer_iso_lx2k = self.nixosConfigurations.installer_iso_lx2k.config.system.build.isoImage;

      installer_sd_image_aarch64-linux = self.nixosConfigurations.installer_sd_image_aarch64-linux.config.system.build.sdImage;
      installer_sd_image_kukui_fennel14 = self.nixosConfigurations.installer_sd_image_kukui_fennel14.config.system.build.sdImage;
      installer_sd_image_asurada_spherion = self.nixosConfigurations.installer_sd_image_asurada_spherion.config.system.build.sdImage;

      rhubarb_sd_image = self.nixosConfigurations.rhubarb.config.system.build.sdImage;
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
          webauthn-tiny.overlays.default
        ];
      };
    in
    pkgs.lib.recursiveUpdate (commonDerivations pkgs) {
      installer_sd_image_x86_64-linux = self.nixosConfigurations.installer_sd_image_x86_64-linux.config.system.build.sdImage;

      inherit (pkgs)
        coreboot-qemu-x86
        coreboot-volteer-elemi
        ;

      inherit (pkgs.pkgsCross.aarch64-multiplatform)
        coreboot-asurada-spherion
        coreboot-kukui-fennel14
        coreboot-qemu-aarch64
        ipwatch
        linux_cn913x
        linux_mediatek
        runner-nix
        ubootCN9130_CF_Pro
        webauthn-tiny
        ;
    };
}
