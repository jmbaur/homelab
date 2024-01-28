{ lib, pkgs, ... }: {
  nixpkgs.hostPlatform = "aarch64-linux";

  hardware.bpi-r3.enable = true;

  # {{{ TODO(jared): delete this
  users.allowNoPasswordLogin = true;
  users.users.root.password = lib.warn "EMPTY ROOT PASSWORD, DO NOT USE IN 'PRODUCTION'" "";
  boot.initrd.systemd.emergencyAccess = true;
  # }}}

  environment.systemPackages = [ pkgs.mtdutils ];

  custom.image = {
    enable = true;
    bootVariant = "fit-image";
    primaryDisk = "/dev/disk/by-path/platform-11230000.mmc";
    ubootLoadAddress = "0x80000000";
    ubootBootMedium.type = "mmc";
  };
}
