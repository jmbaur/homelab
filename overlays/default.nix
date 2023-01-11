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
          u-rootInitramfs
          xremap
          yamlfmt
          zf
          ;

        bitwarden-bemenu = prev.callPackage ./bitwarden-bemenu.nix { };
        git-get = prev.callPackage ./git-get { };
        j = prev.callPackage ./j.nix { };
        macgen = prev.callPackage ./macgen.nix { };
        mirror-to-x = prev.callPackage ./mirror-to-x.nix { };
        pomo = prev.callPackage ./pomo { };
        v4l-show = prev.callPackage ./v4l-show.nix { };
        wip = prev.writeShellScriptBin "wip" ''git commit --no-verify --no-gpg-sign --all --message "WIP" && git push'';
        ixio = prev.writeShellScriptBin "ixio" "${prev.curl}/bin/curl -F 'f:1=<-' ix.io";
        stevenblack-hosts = prev.linkFarm "hosts" (
          let
            repo = (prev.fetchgit {
              inherit (prev.lib.importJSON ./stevenblack_hosts.json)
                url rev sha256;
            });
          in
          [
            { name = "hosts"; path = "${repo}/hosts"; }
          ]
        );

        vimPlugins = prev.vimPlugins // {
          jmbaur-settings = prev.vimUtils.buildVimPlugin {
            pname = "jmbaur-settings";
            version = "0.0.0";
            src = ./neovim/settings;
          };
          smartyank-nvim =
            let
              smartyank-nvim-src = prev.lib.importJSON
                ./ibhagwan_smartyank-nvim.json;
            in
            prev.vimUtils.buildVimPlugin {
              pname = "smartyank-nvim";
              version = smartyank-nvim-src.rev;
              src = prev.fetchgit { inherit (smartyank-nvim-src) url sha256 rev; };
            };
        };
        neovim = prev.callPackage ./neovim { inherit (final) vimPlugins; };
        neovim-boring = prev.writeShellScriptBin
          "nvimb"
          ''exec -a "$0" ${final.neovim.override { boring = true; }}/bin/nvim "$@"'';
        neovim-image = prev.callPackage ./neovim-image.nix { inherit (final) neovim; };

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

        ubootCN9130_CF_Pro = prev.callPackage ./ubootCN9130_CF_Pro.nix { inherit cn913x_build; };

        linux_cn913x = prev.callPackage ./kernels/linux_cn913x.nix { inherit cn913x_build; };
        linux_mediatek = prev.callPackage ./kernels/linux_mediatek.nix { };

        linuxboot-qemu-aarch64-fitimage = final.mkFitImage {
          boardName = "qemu-aarch64";
          kernel = final.tinyboot-kernel;
          initramfs = "${final.tinyboot-initramfs.override { tty = "ttyAMA0"; }}/initrd";
          # NOTE: See here as to why qemu needs to be in depsBuildBuild and
          # not nativeBuildInputs:
          # https://github.com/NixOS/nixpkgs/pull/146583
          dtb = prev.callPackage
            ({ runCommand, qemu }: runCommand "qemu-aarch64.dtb" { depsBuildBuild = [ qemu ]; } ''
              qemu-system-aarch64 \
                -M virt,secure=on,virtualization=on,dumpdtb=$out \
                -cpu cortex-a53 -m 2G -nographic \
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
        coreboot-toolchain = prev.callPackage ./coreboot-toolchain { };
        buildCoreboot = prev.callPackage ./coreboot { inherit (final) coreboot-toolchain; };
        coreboot-qemu-x86 = final.buildCoreboot {
          boardName = "qemu-x86";
          configfile = ./coreboot/qemu-x86.config;
          extraConfig = ''
            CONFIG_PAYLOAD_FILE="${final.tinyboot-kernel}/bzImage"
            CONFIG_LINUX_INITRD="${final.tinyboot-initramfs.override { tty = "ttyS0"; }}/initrd"
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
                url = "https://github.com/intel/FSP/raw/6f2f17f3d3397cc2f00a644e218980bb33e06f66/TigerLakeFspBinPkg/Client/SampleCode/Vbt/Vbt.bin";
                sha256 = "sha256-IDp05CcwaTOucvXF8MmsTg1qyYKXU3E5xw2ZUisUXt4=";
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
