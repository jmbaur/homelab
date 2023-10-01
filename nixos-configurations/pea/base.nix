{ config, lib, pkgs, modulesPath, ... }: {
  disabledModules = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/all-hardware.nix"
  ];
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


  # limit the number of tools needing to be built
  system.disableInstallerTools = true;
  environment.defaultPackages = [ ];

  # TODO(jared): these should probably be fixed in nixpkgs? They all assume
  # `config.systemd.package` is not set to something custom.
  nixpkgs.overlays = [
    (_: prev: {
      util-linux = prev.util-linux.override {
        nlsSupport = false;
        ncursesSupport = false;
        systemdSupport = false;
        translateManpages = false;
      };

      mdadm = prev.mdadm.override {
        udev = config.systemd.package;
      };

      tmux = prev.tmux.override {
        withSystemd = false;
      };

      dhcpcd = prev.dhcpcd.override {
        udev = config.systemd.package;
      };

      procps = prev.procps.override {
        withSystemd = false;
      };

      v4l-utils = prev.v4l-utils.override {
        udev = config.systemd.package;
      };
    })
  ];

  services.lvm.enable = false;
}
