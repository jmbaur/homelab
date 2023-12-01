{
  imports = [ ./hardware.nix ];

  networking.hostName = "pumpkin";
  hardware.bluetooth.enable = true;

  boot.initrd.systemd.enable = true;

  services.fwupd.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  custom = {
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
    users.jared.enable = true;
  };
}
