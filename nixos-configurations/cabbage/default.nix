{ ... }: {
  imports = [
    (import ../disko-single-disk-encrypted.nix "/dev/nvme0n1")
    ./hardware.nix
  ];

  custom.users.jared.enable = true;
  custom.dev.enable = true;
  custom.gui.enable = true;

  boot.initrd.systemd.enable = true;
  services.fwupd.enable = true;
  zramSwap.enable = true;
  hardware.bluetooth.enable = true;
  networking.wireless.iwd.enable = true;
}
