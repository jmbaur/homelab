{
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
  writeArgcShellApplication,
}:

writeArgcShellApplication {
  name = "nixos-recovery";

  runtimeInputs = [
    "/run/wrappers" # mount
    btrfs-progs # mkfs.btrfs
    cryptsetup
    curl
    dosfstools # mkfs.vfat
    jq
    nix # nix-env
    nixos-install
    systemd # systemd-repart
    util-linux # blockdev
  ];

  text = lib.fileContents ./nixos-recovery.bash;
}
