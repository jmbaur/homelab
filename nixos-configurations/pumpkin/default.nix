{
  nixpkgs.hostPlatform = "aarch64-linux";
  hardware.deviceTree.name = "marvell/armada-8040-mcbin.dtb";

  custom.image.boot.uefi.enable = true;
  custom.server.enable = true;
  custom.basicNetwork.enable = true;
}
