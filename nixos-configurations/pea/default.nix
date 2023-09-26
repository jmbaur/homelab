{ lib, pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/sd-card/sd-image-armv7l-multiplatform.nix" ];

  nixpkgs.hostPlatform = lib.recursiveUpdate lib.systems.platforms.armv7l-hf-multiplatform {
    config = "armv7l-unknown-linux-gnueabihf";
    linux-kernel = {
      name = "sunxi";
      baseConfig = "sunxi_defconfig";
      autoModules = false;
      preferBuiltin = true;
    };
  };

  custom.crossCompile.enable = true;

  users.allowNoPasswordLogin = true;

  sdImage.populateFirmwareCommands = lib.mkForce ""; # don't need rpi-specific files
  sdImage.postBuildCommands = ''
    dd ${pkgs.ubootBananaPim2Zero}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc,sync
  '';

  hardware.deviceTree.enable = true;
  hardware.deviceTree.filter = "sunxi-bananapi-m2-plus*";

  systemd.package = pkgs.systemdMinimal;
}
