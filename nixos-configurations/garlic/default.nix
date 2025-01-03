{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    # TODO(jared): belongs in hardware module
    {
      hardware.qualcomm.enable = true;

      nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

      hardware.deviceTree.name = "qcom/x1e78100-lenovo-thinkpad-t14s.dtb";

      hardware.firmware = [
        pkgs.linux-firmware
        pkgs.t14s-firmware
      ];

      boot.kernelPackages = pkgs.linuxPackagesFor (
        pkgs.callPackage
          (
            { buildLinux, ... }@args:
            buildLinux (
              args
              // {
                version = "6.13.0";
                modDirVersion = "6.13.0-rc4";

                src = pkgs.fetchFromGitHub {
                  owner = "jhovold";
                  repo = "linux";
                  # wip/x1e80100-6.13-rc4
                  rev = "f8ef0dcee4a61f686655f9be82d0576b99612dec";
                  hash = "sha256-y0Vl3yWxsE7V+cmXemdU19PSQRLS6MXBC7h9l4Zjyvk=";
                };
                kernelPatches = (args.kernelPatches or [ ]);

                extraMeta.branch = "6.13";
              }
              // (args.argsOverride or { })
            )
          )
          {
            defconfig = "johan_defconfig";
          }
      );

      boot.consoleLogLevel = 7;

      boot.kernelParams = [
        "clk_ignore_unused"
        "pd_ignore_unused"
      ];

      boot.initrd.includeDefaultModules = false;

      boot.initrd.availableKernelModules = [
        # storage
        "nvme"
        "tcsrcc_x1e80100"
        "phy_qcom_qmp_pcie"
        "pcie_qcom"

        # keyboard
        "i2c_hid_of"
        "i2c_qcom_geni"
      ];
    }
    {
      custom.dev.enable = true;
      custom.desktop.enable = false;
      custom.image = {
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/nvme0n1";
      };
    }
  ];
}
