{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.initrd.availableKernelModules = [
        "dwmac_rk"
        "nvme"
        "phy-rockchip-naneng-combphy"
        "rtc_hym8563"
      ];

      hardware.deviceTree = {
        enable = true;
        name = "rockchip/rk3588s-orangepi-5.dtb";
        overlays = [
          {
            name = "use-standard-baudrate";
            dtsText = ''
              /dts-v1/;
              /plugin/;

              / {
                compatible = "rockchip,rk3588s";
              };

              &{/chosen} {
                stdout-path = "serial2:115200n8";
              };
            '';
          }
        ];
      };

      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem pkg.pname [ "rkbin" ];
      system.build.firmware = pkgs.uboot-orangepi-5-rk3588s.override {
        artifacts = [ "u-boot-rockchip-spi.bin" ];
        extraStructuredConfig = with lib.kernel; {
          BAUDRATE = freeform 115200; # c'mon rockchip
          USE_PREBOOT = yes;
          PREBOOT = freeform "pci enum; usb start; nvme scan";
        };
      };

      environment.systemPackages = [
        pkgs.uboot-env-tools
        pkgs.mtdutils
        (pkgs.writeShellScriptBin "update-firmware" ''
          ${lib.getExe' pkgs.mtdutils "flashcp"} \
            --verbose \
            ${config.system.build.firmware}/u-boot-rockchip-spi.bin \
            /dev/mtd0
        '')
      ];

      hardware.firmware = [
        (pkgs.extractLinuxFirmware "mali-firmware" [ "arm/mali/arch10.8/mali_csffw.bin" ])
      ];
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
      custom.common.nativeBuild = true;
    }
    (
      let
        gitUser = config.users.users.git;
      in
      {
        users.groups.git = { };
        users.users.git = {
          isSystemUser = true;
          home = "/var/lib/git";
          createHome = false;
          group = config.users.groups.git.name;
          shell = lib.getExe' pkgs.git "git-shell";
          packages = [
            pkgs.git
            pkgs.natscli # for `nats pub`
          ];
          openssh.authorizedKeys.keys = [
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo="
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo="
          ];
        };

        systemd.tmpfiles.settings."10-git-home" = {
          ${gitUser.home}.d = {
            mode = "700";
            user = gitUser.name;
            group = gitUser.group;
          };
          "${gitUser.home}/git-shell-commands"."L+".argument =
            "${pkgs.homelab-git-shell-commands}/git-shell-commands";
        };

        services.static-web-server = {
          enable = true;
          listen = "[::]:80";
          root = "/var/lib/git-html";
        };

        sops.secrets = {
          nix = { };
          mirror = { };
        };

        services.harmonia = {
          enable = true;
          signKeyPaths = [ config.sops.secrets.nix.path ];
          settings.bind = "[::]:5000";
        };

        services.nats.enable = true;

        custom.yggdrasil.all.allowedTCPPorts = [
          5000
          80
          config.services.nats.port
        ];

        systemd.services.update-repository-html = {
          startAt = [ "daily" ];
          serviceConfig = {
            User = gitUser.name;
            Group = gitUser.group;
            StateDirectory = "git-html";
            RuntimeDirectory = "git-html";
          };

          path = [
            pkgs.git
            pkgs.imagemagick
            pkgs.stagit
          ];

          script = ''
            new_html_dir=$(mktemp --directory --tmpdir="$RUNTIME_DIRECTORY")
            trap 'rm -rf $new_html_dir' EXIT

            magick -size 100x100 xc:#1f3023 "''${new_html_dir}/logo.png"

            declare -a repos
            while read -r repo_dir; do
              if [[ $(git -C "$repo_dir" rev-parse --is-bare-repository 2>/dev/null) != "true" ]]; then
                continue
              fi

              repos+=("$repo_dir")
              repo_name=$(basename "$repo_dir")
              repo_html_dir="''${new_html_dir}/''${repo_name}"
              echo "Creating HTML for repository $repo_name"
              mkdir -p "$repo_html_dir"
              pushd "$repo_html_dir" >/dev/null || exit
              stagit "$repo_dir"
              ln -sf "''${STATE_DIRECTORY}/logo.png" "''${repo_html_dir}/logo.png"
              popd >/dev/null || exit
            done < <(find ${gitUser.home} -maxdepth 1 -mindepth 1 -type d)

            stagit-index "''${repos[@]}" >"''${new_html_dir}/index.html"

            rm -rf $STATE_DIRECTORY/*
            mv $new_html_dir/* "$STATE_DIRECTORY"
          '';
        };
      }
    )
  ];
}
