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
                modDirVersion = "6.13.0-rc7";

                src = pkgs.fetchFromGitHub {
                  owner = "jhovold";
                  repo = "linux";
                  # wip/x1e80100-6.13-rc7
                  rev = "a99c4f26cb7c7568967d30ae8aacb397732327e7";
                  hash = "sha256-R6+PZjL1UD2w5aWBty+sSzoO61l4gzqhjgTj7sfL1oE=";
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

      # TODO(jared): ACPI not enabled in johan_defconfig, needed by tpm-crb
      # kernel module.
      boot.initrd.systemd.tpm2.enable = false;
      custom.recovery.modules = [
        {
          boot.initrd.includeDefaultModules = false;
          boot.initrd.systemd.tpm2.enable = false;
        }
      ];
    }
    {
      custom.dev.enable = true;
      custom.desktop.enable = false;
      custom.common.nativeBuild = true;
      custom.recovery.targetDisk = "/dev/nvme0n1";
    }
  ];
}
