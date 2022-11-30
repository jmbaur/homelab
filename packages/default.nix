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
      macgen
      mirror-to-x
      neovim
      outlook-webapp
      pd-notify
      pomo
      slack-webapp
      spotify-webapp
      stevenblack-hosts
      teams-webapp
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
        linux_chromiumos_mediatek
        linux_cn913x
        ubootCN9130_CF_Pro
        ;

      installer_iso_lx2k = self.nixosConfigurations.installer_iso_lx2k.config.system.build.isoImage;

      installer_sd_image = self.nixosConfigurations.installer_sd_image.config.system.build.sdImage;
      installer_sd_image_kukui_fennel14 = self.nixosConfigurations.installer_sd_image_kukui_fennel14.config.system.build.sdImage;

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
      inherit (pkgs.pkgsCross.aarch64-multiplatform)
        ipwatch
        linux_chromiumos_mediatek
        linux_cn913x
        runner-nix
        ubootCN9130_CF_Pro
        webauthn-tiny
        ;
    };
}
