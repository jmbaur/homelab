{ pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "cma=256M" ];
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_cn913x;
  hardware.deviceTree = {
    enable = true;
    filter = "cn913*.dtb";
  };
}
