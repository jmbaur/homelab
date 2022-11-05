{ pkgs, ... }: {
  boot.kernelParams = [
    "console=ttyAMA0,115200"
    "arm-smmu.disable_bypass=0"
    "iommu.passthrough=1"
    "amdgpu.pcie_gen_cap=0x4"
    "usbcore.autosuspend=-1"
  ];
  boot.kernelPackages = pkgs.linuxPackages_6_0;

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
}
