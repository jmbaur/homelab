inputs: with inputs;
let
  commonDerivations = pkgs: {
    installer_iso = self.nixosConfigurations."installer_iso_${pkgs.system}".config.system.build.isoImage;

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
      discord-webapp
      edk2-uefi-coreboot-payload
      flarectl
      flashrom-cros
      flashrom-dasharo
      git-get
      gobar
      gosee
      grafana-dashboards
      ixio
      j
      jmbaur-github-ssh-keys
      jmbaur-keybase-pgp-keys
      macgen
      mirror-to-x
      neovim
      neovim-image
      outlook-webapp
      pd-notify
      pomo
      slack-webapp
      spotify-webapp
      teams-webapp
      u-rootInitramfs
      v4l-show
      wezterm
      wip
      xremap
      yamlfmt
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
        linux_cn913x
        linux_mediatek
        linux_orangepi-5
        ubootCN9130_CF_Pro
        ;

      inherit (pkgs.pkgsCross.armv7l-hf-multiplatform)
        linux_mvebu_v7
        ubootClearfogSpi
        ;

      installer_iso_lx2k = self.nixosConfigurations.installer_iso_lx2k.config.system.build.isoImage;

      installer_sd_image = self.nixosConfigurations.installer_sd_image_aarch64-linux.config.system.build.sdImage;
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
      installer_sd_image = self.nixosConfigurations.installer_sd_image_x86_64-linux.config.system.build.sdImage;

      inherit (pkgs)
        coreboot-qemu-x86
        coreboot-volteer-elemi
        ;

      inherit (pkgs.pkgsCross.armv7l-hf-multiplatform)
        linux_mvebu_v7
        ubootClearfogSpi
        ;

      inherit (pkgs.pkgsCross.aarch64-multiplatform)
        coreboot-asurada-spherion
        coreboot-kukui-fennel14
        coreboot-qemu-aarch64
        ipwatch
        linux_cn913x
        linux_mediatek
        linux_orangepi-5
        runner-nix
        ubootCN9130_CF_Pro
        webauthn-tiny
        ;
    };
}
