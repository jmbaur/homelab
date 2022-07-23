inputs: with inputs; {
  default = {
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
          patches = [
            {
              name = "cn913x-based-COM-express-type";
              patch = "${inputs.cn913x_build}/patches/linux/0001-arm64-dts-cn913x-add-cn913x-based-COM-express-type-.patch";
            }
            {
              name = "cn913x-COM-device-trees";
              patch = "${inputs.cn913x_build}/patches/linux/0002-arm64-dts-cn913x-add-cn913x-COM-device-trees-to-the.patch";
            }
            {
              name = "device-trees-cn913x-rev-1_1";
              patch = "${inputs.cn913x_build}/patches/linux/0004-dts-update-device-trees-to-cn913x-rev-1.1.patch";
            }
            {
              name = "DTS-cn9130-device-tree";
              patch = "${inputs.cn913x_build}/patches/linux/0005-DTS-update-cn9130-device-tree.patch";
            }
            {
              name = "spi-clock-frequency-10MHz";
              patch = "${inputs.cn913x_build}/patches/linux/0007-update-spi-clock-frequency-to-10MHz.patch";
            }
            {
              name = "som-clearfog-base-and-pro";
              patch = "${inputs.cn913x_build}/patches/linux/0009-dts-cn9130-som-for-clearfog-base-and-pro.patch";
            }
            {
              name = "usb2-interrupt-btn";
              patch = "${inputs.cn913x_build}/patches/linux/0010-dts-add-usb2-support-and-interrupt-btn.patch";
            }
            {
              name = "cn9131-cf-solidwan";
              patch = "${inputs.cn913x_build}/patches/linux/0011-linux-add-support-cn9131-cf-solidwan.patch";
            }
            {
              name = "cn9131-bldn-mbv";
              patch = "${inputs.cn913x_build}/patches/linux/0012-linux-add-support-cn9131-bldn-mbv.patch";
            }
          ];
        in
        {
          options.hardware.cn913x.enable = lib.mkEnableOption "cn913x hardware";
          config = lib.mkIf cfg.enable {
            boot.kernelPackages = pkgs.linuxPackages_5_18;
            boot.kernelPatches = patches;
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
