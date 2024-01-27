{ lib, ... }: {
  nixpkgs.hostPlatform = "aarch64-linux";

  hardware.bpi-r3.enable = true;

  # {{{ TODO(jared): delete this
  users.allowNoPasswordLogin = true;
  users.users.root.password = lib.warn "EMPTY ROOT PASSWORD, DO NOT USE IN 'PRODUCTION'" "";
  # }}}

  custom.image = {
    enable = true;
    bootVariant = "fit-image";

    # TODO(jared): confirm below configuration
    primaryDisk = "/dev/mmcblk0";
    ubootLoadAddress = "0x43040000";
    ubootBootMedium.type = "mmc";
  };
}
