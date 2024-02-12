{ pkgs, ... }: {
  imports = [ ./router.nix ];

  nixpkgs.hostPlatform = "aarch64-linux";

  hardware.bpi-r3.enable = true;

  users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

  custom.image = {
    enable = true;
    primaryDisk = "/dev/disk/by-path/platform-11230000.mmc";
    uboot = {
      enable = true;
      kernelLoadAddress = "0x50000000";
      bootMedium.type = "mmc";
    };
  };
}
