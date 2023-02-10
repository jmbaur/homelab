inputs: with inputs; {
  default = nixpkgs.lib.composeManyExtensions [
    gosee.overlays.default
    tinyboot.overlays.default
    (final: prev:
      let
        out-of-tree = prev.callPackage ./out-of-tree.nix { };
      in
      {
        inherit (out-of-tree)
          cicada
          coredns-utils
          depthcharge-tools
          flarectl
          flashrom-cros
          flashrom-dasharo
          stevenblack-blocklist
          u-rootInitramfs
          xremap
          yamlfmt
          ;

        wezterm = prev.wezterm.overrideAttrs (_: {
          patches = [
            (prev.fetchpatch {
              name = "wezterm-wayland-hide-cursor.patch";
              url = "https://patch-diff.githubusercontent.com/raw/wez/wezterm/pull/2977.patch";
              sha256 = "sha256-X1nGOFPJRx1YjYgAeKTFDfViXn/LExiMhbqWvjEDUM4=";
            })
          ];
        });

        bitwarden-bemenu = prev.callPackage ./bitwarden-bemenu.nix { };
        git-get = prev.callPackage ./git-get { };
        j = prev.callPackage ./j.nix { };
        macgen = prev.callPackage ./macgen.nix { };
        mirror-to-x = prev.callPackage ./mirror-to-x.nix { };
        pomo = prev.callPackage ./pomo { };
        v4l-show = prev.callPackage ./v4l-show.nix { };
        wip = prev.writeShellScriptBin "wip" ''git commit --no-verify --no-gpg-sign --all --message "WIP"; git push'';
        ixio = prev.writeShellScriptBin "ixio" "${prev.curl}/bin/curl -F 'f:1=<-' ix.io";

        vimPlugins = prev.vimPlugins // {
          jmbaur-settings = prev.vimUtils.buildVimPlugin {
            pname = "jmbaur-settings";
            version = "unversioned";
            src = ./neovim/settings;
          };
          inherit (out-of-tree) smartyank-nvim;
        };
        neovim = prev.callPackage ./neovim { inherit (final) vimPlugins; };
        neovim-boring = prev.writeShellScriptBin
          "nvimb"
          ''exec -a "$0" ${final.neovim.override { boring = true; }}/bin/nvim "$@"'';

        mkWaylandVariant = prev.callPackage ./mkWaylandVariant.nix { };
        brave-wayland = final.mkWaylandVariant
          prev.brave;
        chromium-wayland = final.mkWaylandVariant
          prev.chromium;
        google-chrome-wayland = final.mkWaylandVariant
          prev.google-chrome;
        bitwarden-wayland = final.mkWaylandVariant
          prev.bitwarden;
        discord-wayland = final.mkWaylandVariant
          prev.discord;
        signal-desktop-wayland = final.mkWaylandVariant
          prev.signal-desktop;
        slack-wayland = final.mkWaylandVariant
          prev.slack;

        mkWebApp = prev.callPackage
          ./mkWebApp.nix
          { chromium = final.chromium-wayland; };
        discord-webapp = final.mkWebApp
          "discord"
          "https://discord.com/app";
        outlook-webapp = final.mkWebApp
          "outlook"
          "https://outlook.office365.com/mail";
        slack-webapp = final.mkWebApp
          "slack"
          "https://app.slack.com/client";
        spotify-webapp = final.mkWebApp
          "spotify"
          "https://open.spotify.com";
        teams-webapp = final.mkWebApp
          "teams"
          "https://teams.microsoft.com";

        grafana-dashboards = prev.callPackage ./grafana-dashboards { };

        # Enable fit images (w/signatures) and modify some hardware.
        # - CON2 (configured for PCI) is located nearest the CPU
        # - CON3 (configured for SATA) is located nearest the edge of the device
        ubootClearfog = prev.ubootClearfog.override {
          extraConfig = ''
            CONFIG_CLEARFOG_CON2_PCI=y
            CONFIG_CLEARFOG_CON3_PCI=n
            CONFIG_CLEARFOG_CON2_SATA=n
            CONFIG_CLEARFOG_CON3_SATA=y
            CONFIG_CLEARFOG_SFP_25GB=y
            CONFIG_FIT=y
            CONFIG_FIT_SIGNATURE=y
            CONFIG_RSA=y
          '';
          # default boot device is mmc
          extraMeta.bootDevice = "mmc";
        };
        ubootClearfogUart = prev.ubootClearfog.override {
          extraConfig = final.ubootClearfog.extraConfig + ''
            CONFIG_MVEBU_SPL_BOOT_DEVICE_MMC=n
            CONFIG_MVEBU_SPL_BOOT_DEVICE_UART=y
          '';
          extraMeta.bootDevice = "uart";
        };
        ubootClearfogSpi = prev.ubootClearfog.override {
          extraConfig = final.ubootClearfog.extraConfig + ''
            CONFIG_MVEBU_SPL_BOOT_DEVICE_MMC=n
            CONFIG_MVEBU_SPL_BOOT_DEVICE_SPI=y
          '';
          postInstall = ''
            dd bs=1M count=4 if=/dev/zero of=$out/spi.img
            dd conv=notrunc if=$out/u-boot-spl.kwb of=$out/spi.img
          '';
          extraMeta.bootDevice = "spi";
        };
        ubootCN9130_CF_Pro = prev.callPackage ./ubootCN9130_CF_Pro.nix { inherit cn913x_build; };

        linux_cn913x = prev.callPackage ./kernels/linux_cn913x.nix { inherit cn913x_build; };
        linux_mediatek = prev.callPackage ./kernels/linux_mediatek.nix { };
        linux_mvebu_v7 = prev.callPackage ./kernels/linux_mvebu_v7.nix { };
        linux_orangepi-5 = prev.callPackage ./kernels/linux_orangepi-5.nix { };

        linuxboot-qemu-aarch64-fitimage = final.mkFitImage {
          boardName = "qemu-aarch64";
          kernel = final.tinyboot-kernel;
          initramfs = "${final.tinyboot-initramfs.override { shellTTY = "ttyAMA0"; }}/initrd";
          # NOTE: See here as to why qemu needs to be in depsBuildBuild and
          # not nativeBuildInputs:
          # https://github.com/NixOS/nixpkgs/pull/146583
          dtb = prev.callPackage
            ({ runCommand, qemu }: runCommand "qemu-aarch64.dtb" { depsBuildBuild = [ qemu ]; } ''
              qemu-system-aarch64 \
                -M virt,secure=on,virtualization=on,dumpdtb=$out \
                -cpu cortex-a53 -m 2G -nographic \
                -device virtio-gpu-pci \
                -drive format=raw,if=virtio,file=$(mktemp)
            '')
            { };
        };
        linuxboot-mediatek-fitimage = final.mkFitImage {
          boardName = "mediatek";
          kernel = final.tinyboot-kernel;
          initramfs = "${final.tinyboot-initramfs}/initrd";
          dtbPattern = "(mt8183|mt8192)";
        };

        edk2-uefi-coreboot-payload = prev.callPackage ./edk2-coreboot.nix { };

        mkFitImage = prev.callPackage ./fitimage { };
        buildCoreboot = prev.callPackage ./coreboot {
          # built with meson, includes pkgconfig support
          flashrom = final.flashrom-cros;
        };
        coreboot-qemu-x86 = final.buildCoreboot {
          boardName = "qemu-x86";
          configfile = ./coreboot/qemu-x86.config;
          extraConfig = ''
            CONFIG_PAYLOAD_FILE="${final.tinyboot-kernel}/bzImage"
            CONFIG_LINUX_INITRD="${final.tinyboot-initramfs.override { shellTTY = "ttyS0"; }}/initrd"
          '';
        };
        coreboot-qemu-aarch64 = final.buildCoreboot {
          inherit (final.linuxboot-qemu-aarch64-fitimage) boardName;
          configfile = ./coreboot/qemu-aarch64.config;
          extraConfig = ''
            CONFIG_PAYLOAD_FILE="${final.linuxboot-qemu-aarch64-fitimage}/uImage"
          '';
        };
        coreboot-volteer-elemi = final.buildCoreboot {
          boardName = "volteer-elemi";
          configfile = ./coreboot/volteer-elemi.config;
          extraConfig =
            let
              vbt = prev.fetchurl {
                url = "https://github.com/intel/FSP/raw/d85493d0605921f46afab3445be01da90f0a8062/TigerLakeFspBinPkg/Client/SampleCode/Vbt/Vbt.bin";
                sha256 = "sha256-IDp05CcwaTOucvXF8MmsTg1qyYKXU3E5xw2ZUisUXt4=";
              };
            in
            ''
              CONFIG_INTEL_GMA_VBT_FILE="${vbt}"
              CONFIG_PAYLOAD_FILE="${final.tinyboot-kernel}/bzImage"
              CONFIG_LINUX_INITRD="${final.tinyboot-initramfs}/initrd"
            '';
        };
        coreboot-msi-ms-7d25 = final.buildCoreboot {
          boardName = "msi-ms-7d25";
          configfile = ./coreboot/msi-ms-7d25.config;
          extraConfig =
            let
              vbt = prev.fetchurl {
                url = "https://github.com/intel/FSP/raw/d85493d0605921f46afab3445be01da90f0a8062/AlderLakeFspBinPkg/Client/AlderLakeP/SampleCode/Vbt/Vbt.bin";
                sha256 = "sha256-bmdHLfbNIR1zCt2OMxCCLCPoqJskaUbnBZYQcJoJ/LQ=";
              };
            in
            ''
              CONFIG_INTEL_GMA_VBT_FILE="${vbt}"
              CONFIG_PAYLOAD_FILE="${final.tinyboot-kernel}/bzImage"
              CONFIG_LINUX_INITRD="${final.tinyboot-initramfs}/initrd"
            '';
        };
        coreboot-kukui-fennel14 = final.buildCoreboot {
          boardName = "kukui-fennel14";
          configfile = ./coreboot/kukui-fennel.config;
          extraConfig = ''
            CONFIG_PAYLOAD_FILE="${final.linuxboot-mediatek-fitimage}/uImage"
          '';
        };
        coreboot-asurada-spherion = final.buildCoreboot {
          boardName = "asurada-spherion";
          configfile = ./coreboot/asurada-spherion.config;
          extraConfig = ''
            CONFIG_PAYLOAD_FILE="${final.linuxboot-mediatek-fitimage}/uImage"
          '';
        };

        jmbaur-keybase-pgp-keys = prev.fetchurl {
          url = "https://keybase.io/jaredbaur/pgp_keys.asc";
          sha256 = "sha256-R2a+bF7E6Zogl5XWsjrK5dkCAvK6K2h/bje37aYSgGc=";
        };
        jmbaur-github-ssh-keys = prev.fetchurl {
          url = "https://github.com/jmbaur.keys";
          sha256 = "sha256-AWOgwTfJ7a2t+8VOViNQCXMDGe+zx29jHOqgFPnlzCo=";
        };
      })
  ];
}
