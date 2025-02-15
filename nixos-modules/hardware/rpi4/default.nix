{
  config,
  lib,
  pkgs,
  ...
}:

let
  firmwareImage = pkgs.callPackage ./firmware-image.nix { };
in
{
  options.hardware.rpi4.enable = lib.mkEnableOption "rpi4 hardware support";

  config = lib.mkIf config.hardware.rpi4.enable (
    lib.mkMerge [
      {
        # set tsched=0 in pulseaudio config to avoid audio glitches
        # see https://wiki.archlinux.org/title/PulseAudio/Troubleshooting#Glitches,_skips_or_crackling
        services.pulseaudio.configFile = lib.mkOverride 990 (
          pkgs.runCommand "default.pa" { } ''
            sed 's/module-udev-detect$/module-udev-detect tsched=0/' ${config.services.pulseaudio.package}/etc/pulse/default.pa > $out
          ''
        );
      }
      {
        hardware.deviceTree = {
          overlays = [
            {
              name = "bluetooth-overlay";
              dtsText = ''
                /dts-v1/;
                /plugin/;

                / {
                    compatible = "brcm,bcm2711";

                    fragment@0 {
                        target = <&uart0_pins>;
                        __overlay__ {
                                brcm,pins = <30 31 32 33>;
                                brcm,pull = <2 0 0 2>;
                        };
                    };
                };
              '';
            }
          ];
        };
      }
      {
        hardware.deviceTree.overlays = [
          {
            name = "rpi4-cpu-revision";
            dtsText = ''
              /dts-v1/;
              /plugin/;

              / {
                compatible = "raspberrypi,4-model-b";

                fragment@0 {
                  target-path = "/";
                  __overlay__ {
                    system {
                      linux,revision = <0x00d03114>;
                    };
                  };
                };
              };
            '';
          }
        ];
      }
      {
        # Configure for modesetting in the device tree
        hardware.deviceTree = {
          overlays = [
            # Equivalent to:
            # https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/cma-overlay.dts
            {
              name = "rpi4-cma-overlay";
              dtsText = ''
                // SPDX-License-Identifier: GPL-2.0
                /dts-v1/;
                /plugin/;

                / {
                  compatible = "brcm,bcm2711";

                  fragment@0 {
                    target = <&cma>;
                    __overlay__ {
                      size = <(512 * 1024 * 1024)>;
                    };
                  };
                };
              '';
            }
            # Equivalent to:
            # https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/vc4-fkms-v3d-overlay.dts
            {
              name = "rpi4-vc4-fkms-v3d-overlay";
              dtsText = ''
                // SPDX-License-Identifier: GPL-2.0
                /dts-v1/;
                /plugin/;

                / {
                  compatible = "brcm,bcm2711";

                  fragment@1 {
                    target = <&fb>;
                    __overlay__ {
                      status = "disabled";
                    };
                  };

                  fragment@2 {
                    target = <&firmwarekms>;
                    __overlay__ {
                      status = "okay";
                    };
                  };

                  fragment@3 {
                    target = <&v3d>;
                    __overlay__ {
                      status = "okay";
                    };
                  };

                  fragment@4 {
                    target = <&vc4>;
                    __overlay__ {
                      status = "okay";
                    };
                  };
                };
              '';
            }
          ];
        };

        # Also configure the system for modesetting.

        services.xserver.videoDrivers = lib.mkBefore [
          "modesetting" # Prefer the modesetting driver in X11
          "fbdev" # Fallback to fbdev
        ];
      }
      {
        nixpkgs.hostPlatform = "aarch64-linux";

        # Undo the settings we set in <homelab/nixos-modules/server.nix>, they
        # doesn't work on the RPI4.
        #
        # TODO(jared): figure out how to get rid of this.
        systemd.watchdog = {
          runtimeTime = null;
          rebootTime = null;
        };

        system.build.firmwareImage = firmwareImage;

        hardware.deviceTree = {
          name = "broadcom/bcm2711-rpi-4-b.dtb";

          # Add a filter so that we only attempt to apply the devicetree
          # overlays to the right dtb.
          filter = "broadcom/bcm2711-rpi-4-b.dtb";
        };

        boot.kernelParams = [ "console=ttyS1,115200" ];

        environment.etc."fw_env.config".text = ''
          ${config.boot.loader.efi.efiSysMountPoint}/uboot.env 0x0000 0x10000
        '';

        nixpkgs.overlays = [
          (_: prev: { libcec = prev.libcec.override { withLibraspberrypi = true; }; })
        ];

        environment.systemPackages = [
          # install libcec, which includes cec-client (requires root or "video" group, see udev rule below)
          # scan for devices: `echo 'scan' | cec-client -s -d 1`
          # set pi as active source: `echo 'as' | cec-client -s -d 1`
          pkgs.libcec

          pkgs.raspberrypi-eeprom
          pkgs.uboot-env-tools
          (pkgs.writeShellApplication {
            name = "update-firmware";
            runtimeInputs = [
              pkgs.xz
              pkgs.coreutils
            ];
            text = ''
              xz -d <${firmwareImage} | dd bs=4M status=progress oflag=sync of=/dev/disk/by-label/${firmwareImage.label}
            '';
          })
        ];

        boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

        boot.initrd.systemd.tpm2.enable = lib.mkDefault false;

        boot.initrd.availableKernelModules = [
          "usbhid"
          "usb_storage"
          "vc4"
          "pcie_brcmstb" # required for the pcie bus to work
          "reset-raspberrypi" # required for vl805 firmware to load
        ];

        # TODO(jared): filter this down to only the files we need
        # Required for the Wireless firmware
        hardware.enableRedistributableFirmware = true;

        services.udev.extraRules = ''
          # allow access to raspi cec device for video group (and optionally register it as a systemd device, used below)
          KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
        '';
      }
    ]
  );
}
