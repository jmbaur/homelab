{ pkgs, inputs, ... }: {
  imports = [
    (import ../disko-single-disk-encrypted.nix "/dev/mmcblk0")
    ./minimal.nix
  ];

  system.build.installer = (pkgs.nixos ({
    imports = [ inputs.self.nixosModules.default ./minimal.nix ];
    custom.tinyboot-installer.enable = true;
  })).config.system.build.diskImage;

  hardware.kukui-fennel14.enable = true;
  zramSwap.enable = true;

  boot.initrd.systemd.enable = true;

  custom.dev.enable = true;
  custom.gui.enable = true;
  custom.laptop.enable = true;
  custom.remoteBuilders.aarch64builder.enable = true;
  custom.users.jared.enable = true;
}
