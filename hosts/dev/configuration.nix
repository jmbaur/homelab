{ config, lib, pkgs, ... }: {
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
    autoResize = true;
  };

  custom.common.enable = true;
  custom.deploy.enable = true;

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.timeout = 0;

  boot.initrd.availableKernelModules =
    [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  users.users.jared = {
    isNormalUser = true;
    hashedPassword = "$6$bDu4VZR/7w0wJCAE$SCtelDPqyLFYDr6MEbTqVIVJvTUCajRlX1pDw5b1nLywZyUeY6vXusk9An5GF67cprhcg3fwpMOXCLoPBvgL2/";
  };

  services.qemuGuest.enable = true;

  networking.hostName = "dev";
}
