{ pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/sd-card/sd-image-armv7l-multiplatform.nix" ];
  sdImage.postBuildCommands = ''
    dd if=${pkgs.ubootClearfog}/u-boot-spl.kwb of=$img bs=512 seek=1 conv=sync
  '';
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [
    # TODO(jared): console?
  ];
  hardware.deviceTree = {
    enable = true;
    filter = "armada-388-clearfog-*.dtb";
  };
}
