{ lib, pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";

  boot.initrd.availableKernelModules = [ "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  virtualisation.hypervGuest.enable = true;

  custom.dev.enable = true;
  custom.basicNetwork.enable = true;
  custom.server.enable = true;

  hardware.deviceTree.enable = false;

  custom.image = {
    mutableNixStore = true;
    encrypt = false;
    hasTpm2 = false; # hyper-v for arm64 windows does not have tpm support
    boot.uefi.enable = true;
    installer.targetDisk = "/dev/sda";
    postImageCommands = ''
      ${lib.getExe' pkgs.buildPackages.qemu-utils "qemu-img"} convert -f raw -o subformat=dynamic -O vhdx $out/image.raw $out/image.vhdx
      rm $out/image.raw
    '';
  };
}
