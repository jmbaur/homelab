{ lib, pkgs, ... }: {
  nixpkgs.hostPlatform = "aarch64-linux";

  hardware.bpi-r3.enable = true;

  # {{{ TODO(jared): delete this
  users.allowNoPasswordLogin = true;
  users.users.root.password = lib.warn "EMPTY ROOT PASSWORD, DO NOT USE IN 'PRODUCTION'" "";
  # }}}

  environment.systemPackages = with pkgs; [
    mtdutils
    ubootEnvTools
    # TODO(jared): `libmbim` requires building a bunch of extra cruft
  ];

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
