{ config, lib, ... }:
let zfsDisabled = config.custom.disableZfs; in
{
  options.custom.disableZfs = lib.mkEnableOption "disable zfs suppport";
  config = lib.mkIf zfsDisabled {
    boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
  };
}
