{ config, lib, pkgs, ... }: {
  custom.disableZfs = true;
  boot = {
    kernelPackages = pkgs.linuxPackages_testing;
    kernelParams = [ "dtb=/boot/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb" ];
    initrd.kernelModules = [ "phy-qcom-qmp-pcie" "phy-qcom-edp" "i2c_qcom_geni" "i2c_hid_of" ];
    loader.grub = {
      memtest86.enable = lib.mkForce false; # unsupported on aarch64-linux?
      extraFiles."dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb" = "${config.boot.kernelPackages.kernel}/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
      extraPerEntryConfig = ''
        devicetree /boot/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb
      '';
    };
  };
  hardware.deviceTree = {
    enable = true;
    name = "sc8280xp-lenovo-thinkpad-x13s.dtb";
  };
}
