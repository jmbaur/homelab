{ lib, config, ... }:
{
  systemd.tmpfiles.rules = lib.mkIf config.networking.wireless.enable [ "f /etc/wpa_supplicant.conf 600 root root - -" ];
}
