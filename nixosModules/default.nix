inputs: with inputs; {
  default = {
    nixpkgs.overlays = [
      (final: prev: {
        ubootCN9130_CF_Pro = (prev.buildUBoot rec {
          version = "2019.10";
          src = prev.fetchFromGitHub {
            owner = "u-boot";
            repo = "u-boot";
            rev = "v${version}";
            sha256 = "sha256-NhIw4oI1HPjNBWXHJUyScq5qsJ4gx0Al7LNTa95rQTo=";
          };
          extraMeta.platforms = [ "aarch64-linux" ];
          defconfig = "sr_cn913x_cex7_defconfig";
          extraMakeFlags = [ "DEVICE_TREE=cn9130-cf-pro" ];
          filesToInstall = [ "u-boot.bin" ];
        }).overrideAttrs (_: {
          # Nixpkgs has some patches for the raspberry pi that don't apply
          # cleanly to the solidrun version of u-boot.
          patches = [
            "${cn913x_build}/patches/u-boot/0001-cmd-add-tlv_eeprom-command.patch"
            "${cn913x_build}/patches/u-boot/0002-cmd-tlv_eeprom.patch"
            "${cn913x_build}/patches/u-boot/0003-cmd-tlv_eeprom-remove-use-of-global-variable-current.patch"
            "${cn913x_build}/patches/u-boot/0004-cmd-tlv_eeprom-remove-use-of-global-variable-has_bee.patch"
            "${cn913x_build}/patches/u-boot/0005-cmd-tlv_eeprom-do_tlv_eeprom-stop-using-non-api-read.patch"
            "${cn913x_build}/patches/u-boot/0006-cmd-tlv_eeprom-convert-functions-used-by-command-to-.patch"
            "${cn913x_build}/patches/u-boot/0007-cmd-tlv_eeprom-remove-empty-function-implementations.patch"
            "${cn913x_build}/patches/u-boot/0008-cmd-tlv_eeprom-split-off-tlv-library-from-command.patch"
            "${cn913x_build}/patches/u-boot/0009-lib-tlv_eeprom-add-function-for-reading-one-entry-in.patch"
            "${cn913x_build}/patches/u-boot/0010-uboot-marvell-patches.patch"
            "${cn913x_build}/patches/u-boot/0011-uboot-support-cn913x-solidrun-paltfroms.patch"
            "${cn913x_build}/patches/u-boot/0012-add-SoM-and-Carrier-eeproms.patch"
            "${cn913x_build}/patches/u-boot/0013-find-fdtfile-from-tlv-eeprom.patch"
            "${cn913x_build}/patches/u-boot/0014-octeontx2_cn913x-support-distro-boot.patch"
            "${cn913x_build}/patches/u-boot/0015-octeontx2_cn913x-remove-console-variable.patch"
            "${cn913x_build}/patches/u-boot/0016-octeontx2_cn913x-enable-mmc-partconf-command.patch"
            "${cn913x_build}/patches/u-boot/0017-uboot-add-support-cn9131-cf-solidwan.patch"
            "${cn913x_build}/patches/u-boot/0018-uboot-add-support-bldn-mbv.patch"
            ./ramdisk_addr_r.patch
          ];
        });
        armTrustedFirmwareCN9130_CF_Pro = (prev.buildArmTrustedFirmware rec {
          platform = "t9130";
          extraMeta.platforms = [ "aarch64-linux" ];
          filesToInstall = [ "build/${platform}/release/flash-image.bin" ];
          extraMakeFlags = [
            "USE_COHERENT_MEM=0"
            "LOG_LEVEL=20"
            "MV_DDR_PATH=/tmp/mv_ddr_path"
            "CP_NUM=1" # clearfog pro
            "all"
            "fip"
          ];
        }).overrideAttrs (old: rec {
          version = "00ad74c7afe67b2ffaf08300710f18d3dafebb45";
          src = prev.fetchFromGitHub {
            owner = "ARM-software";
            repo = "arm-trusted-firmware";
            rev = version;
            sha256 = "sha256-kHI6H1yym8nWWmLMNOOLUbdtdyNPdNEvimq8EdW0nZw=";
          };
          patches = old.patches ++ [
            "${cn913x_build}/patches/arm-trusted-firmware/0001-ddr-spd-read-failover-to-defualt-config.patch"
            "${cn913x_build}/patches/arm-trusted-firmware/0002-som-sdp-failover-using-crc-verification.patch"
          ];
          preBuild =
            let
              # https://github.com/ARM-software/arm-trusted-firmware/blob/master/docs/plat/marvell/armada/build.rst#tf-a-build-instructions-for-marvell-platforms
              # ATF's build process does some nasty things and needs the .git
              # directory.
              marvell-embedded-processors = prev.fetchgit {
                leaveDotGit = true;
                url = "https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell";
                rev = "305d923e6bc4236cd3b902f6679b0aef9e5fa52d";
                sha256 = "sha256-d9tS0ajHGzVEi1XJzdu0dCvfeEHSPVCrfBqV8qLqC5c=";
              };
            in
            ''
              cp -r ${marvell-embedded-processors} /tmp/mv_ddr_path
              ls -alh /tmp/mv_ddr_path
            '';
          BL33 = "${prev.symlinkJoin {
            name = "armTrustedFirmwareCN9130_CF_Pro-BL33";
            paths = [ final.ubootCN9130_CF_Pro.src final.ubootCN9130_CF_Pro ];
          }}/u-boot.bin";
          SCP_BL2 = "${cn913x_build}/binaries/atf/mrvl_scp_bl2.img";
        });
      })
    ];
    imports = [
      ({ config, pkgs, lib, ... }:
        let
          cfg = config.custom.installer;
        in
        {
          options.custom.installer.enable = lib.mkEnableOption "installer";
          config = lib.mkIf cfg.enable {
            system.stateVersion = "22.11";
            boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_5_18;
            systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
            users.users.nixos.openssh.authorizedKeys.keyFiles = [ (import ./data/jmbaur-ssh-keys.nix) ];
            console.useXkbConfig = true;
            services.xserver.xkbOptions = "ctrl:nocaps";
            nix = {
              package = pkgs.nixUnstable;
              extraOptions = ''
                experimental-features = nix-command flakes
              '';
            };
            environment = {
              variables.EDITOR = "vim";
              systemPackages = with pkgs; [ curl git tmux vim ];
            };
          };
        })
      ({ config, pkgs, lib, ... }:
        let cfg = config.hardware.lx2k; in
        {
          options.hardware.lx2k.enable = lib.mkEnableOption "hardware support for the Honeycomb LX2K board";
          config = lib.mkIf cfg.enable {
            boot.kernelParams = [
              "console=ttyAMA0,115200"
              "arm-smmu.disable_bypass=0"
              "iommu.passthrough=1"
              "amdgpu.pcie_gen_cap=0x4"
              "usbcore.autosuspend=-1"
            ];
            boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_5_18;

            # Setup SFP+ network interfaces early so systemd can pick everything up.
            boot.initrd.extraUtilsCommands = ''
              copy_bin_and_libs ${pkgs.restool}/bin/restool
              copy_bin_and_libs ${pkgs.restool}/bin/ls-main
              copy_bin_and_libs ${pkgs.restool}/bin/ls-addni
                # Patch paths
                sed -i "1i #!$out/bin/sh" $out/bin/ls-main
            '';
            boot.initrd.postDeviceCommands = ''
              ls-addni dpmac.7
              ls-addni dpmac.8
              ls-addni dpmac.9
              ls-addni dpmac.10
            '';
          };
        })
      ({ inputs, config, lib, pkgs, ... }:
        let
          cfg = config.hardware.cn913x;
          kernelPatches = [
            {
              name = "cn913x-based-COM-express-type";
              patch = "${cn913x_build}/patches/linux/0001-arm64-dts-cn913x-add-cn913x-based-COM-express-type-.patch";
            }
            {
              name = "cn913x-COM-device-trees";
              patch = "${cn913x_build}/patches/linux/0002-arm64-dts-cn913x-add-cn913x-COM-device-trees-to-the.patch";
            }
            {
              name = "device-trees-cn913x-rev-1_1";
              patch = "${cn913x_build}/patches/linux/0004-dts-update-device-trees-to-cn913x-rev-1.1.patch";
            }
            {
              name = "DTS-cn9130-device-tree";
              patch = "${cn913x_build}/patches/linux/0005-DTS-update-cn9130-device-tree.patch";
            }
            {
              name = "spi-clock-frequency-10MHz";
              patch = "${cn913x_build}/patches/linux/0007-update-spi-clock-frequency-to-10MHz.patch";
            }
            {
              name = "som-clearfog-base-and-pro";
              patch = "${cn913x_build}/patches/linux/0009-dts-cn9130-som-for-clearfog-base-and-pro.patch";
            }
            {
              name = "usb2-interrupt-btn";
              patch = "${cn913x_build}/patches/linux/0010-dts-add-usb2-support-and-interrupt-btn.patch";
            }
            {
              name = "cn9131-cf-solidwan";
              patch = "${cn913x_build}/patches/linux/0011-linux-add-support-cn9131-cf-solidwan.patch";
            }
            {
              name = "cn9131-bldn-mbv";
              patch = "${cn913x_build}/patches/linux/0012-linux-add-support-cn9131-bldn-mbv.patch";
            }
            {
              name = "cn913x_additions";
              patch = null;
              extraConfig =
                let
                  cn913x_additions = pkgs.runCommandNoCC "cn913x_additions_fixup" { } ''
                    ${pkgs.gnused}/bin/sed 's/CONFIG_\(.*\)=\(.*\)/\1 \2/' ${cn913x_build}/configs/linux/cn913x_additions.config > $out
                  '';
                in
                builtins.readFile "${cn913x_additions}";
            }
          ];
        in
        {
          options.hardware.cn913x.enable = lib.mkEnableOption "cn913x hardware";
          config = lib.mkIf cfg.enable {
            boot = {
              initrd.systemd.enable = true;
              kernelPackages = pkgs.linuxPackages_5_15;
              kernelPatches = kernelPatches;
            };
            hardware.deviceTree = {
              enable = true;
              filter = "cn913*.dtb";
            };
          };
        })
      ({ config, lib, pkgs, ... }:
        let
          cfg = config.hardware.thinkpad-x13s;
        in
        with lib;
        {
          options.hardware.thinkpad-x13s.enable = mkEnableOption "hardware support for ThinkPad X13s";
          config = mkIf cfg.enable {
            boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_5_18.override {
              argsOverride = let rev = "next-20220802"; in
                rec {
                  src = pkgs.fetchurl {
                    url = "https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/snapshot/linux-next-${rev}.tar.gz";
                    sha256 = "sha256-aoykMA0Mbsx0pWp/1ppfkJsq9R3FYn7opRHm3gA7/q0=";
                  };
                  version = "5.18.0-${rev}";
                  modDirVersion = "5.18.0-${rev}";
                };
            });
          };
        })
      ({ config, lib, ... }:
        let
          cfg = config.custom.remoteBoot;
        in
        with lib;
        {
          options.custom.remoteBoot = {
            enable = mkOption {
              type = types.bool;
              default = (config.custom.deployee.enable) && (config.boot.initrd.luks.devices != { });
              description = ''
                Enable remote boot
              '';
            };
            interface = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The interface to use for autoconfiguration during stage-1 boot
              '';
            };
            authorizedKeyFiles = mkOption {
              type = types.listOf types.path;
              default = [ ];
            };
          };
          config = mkIf cfg.enable {
            assertions = [{
              assertion = config.services.openssh.enable;
              message = "OpenSSH must be enabled on host";
            }];
            boot = {
              kernelParams = [
                (if cfg.interface == null then
                  "ip=dhcp"
                else
                  "ip=:::::${cfg.interface}:dhcp")
              ];
              initrd.network = {
                enable = true;
                postCommands = ''
                  echo "cryptsetup-askpass; exit" > /root/.profile
                '';
                ssh = {
                  enable = true;
                  hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ];
                  authorizedKeys = lib.flatten (map
                    (file:
                      (builtins.filter
                        (content: content != "")
                        (lib.splitString "\n" (builtins.readFile file))
                      ))
                    cfg.authorizedKeyFiles);
                };
              };
            };
          };
        })
    ];
  };
}
