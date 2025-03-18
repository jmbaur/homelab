{
  argc,
  btrfs-progs,
  cryptsetup,
  curl,
  dosfstools,
  jq,
  lib,
  nix,
  nixos-install,
  systemd,
  util-linux,
  writeShellApplication,
}:

writeShellApplication {
  name = "nixos-recovery";

  runtimeInputs = [
    "/run/wrappers" # mount
    argc
    btrfs-progs # mkfs.btrfs
    cryptsetup
    curl
    dosfstools # mkfs.vfat
    jq
    nix # nix-env
    nixos-install
    systemd # systemd-repart
    util-linux # sfdisk, blockdev
  ];

  text = lib.fileContents ./nixos-recovery.bash;
}
