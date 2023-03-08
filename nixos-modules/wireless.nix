{ lib, config, ... }: {
  systemd.tmpfiles.rules = lib.optional config.networking.wireless.enable "f /etc/wpa_supplicant.conf 600 root root - -";
}
