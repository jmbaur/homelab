{ lib, pkgs, modulesPath, ... }: {
  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];
  imports = [ "${modulesPath}/installer/sd-card/sd-image-armv7l-multiplatform.nix" ];

  nixpkgs.hostPlatform = lib.recursiveUpdate lib.systems.platforms.armv7l-hf-multiplatform
    (lib.systems.examples.armv7l-hf-multiplatform // {
      linux-kernel = {
        name = "sunxi";
        baseConfig = "sunxi_defconfig";
        autoModules = false;
        preferBuiltin = true;
      };
    });

  custom.crossCompile.enable = true;

  users.allowNoPasswordLogin = true;

  sdImage.populateFirmwareCommands = lib.mkForce ""; # don't need rpi-specific files
  sdImage.postBuildCommands = ''
    dd if=${pkgs.ubootBananaPim2Zero}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc,sync
  '';

  hardware.deviceTree.enable = true;
  hardware.deviceTree.filter = "sun8i-h3-bananapi-m2*.dtb";

  systemd.package = pkgs.systemdMinimal.override {
    withLogind = true;
    withPam = true;
    withTimedated = true;
    withTimesyncd = true;
  };

  # these do not work with pkgs.systemdMinimal
  systemd.coredump.enable = false;
  systemd.oomd.enable = false;

  # limit rebuilding to a minimum
  boot.supportedFilesystems = lib.mkForce [ "vfat" "ext4" ];
  boot.initrd.includeDefaultModules = false;
}
