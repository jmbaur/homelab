{ lib, config, ... }:
{
  systemd.tmpfiles.settings."10-wpa-supplicant" = lib.mkIf config.networking.wireless.enable {
    "/etc/wpa_supplicant.conf".f = {
      user = "root";
      group = "root";
      mode = "600";
    };
  };
}
