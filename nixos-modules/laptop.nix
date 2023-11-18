{ config, lib, ... }:
let
  cfg = config.custom.laptop;
in

{
  options.custom.laptop = with lib; {
    enable = mkEnableOption "laptop config";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.xkbOptions = lib.mkDefault "ctrl:nocaps";

    custom.basicNetwork.enable = true;
    custom.basicNetwork.hasWireless = true;

    systemd.network.wait-online.enable = false;

    # Set a random MAC address for physical network interfaces. Also make sure
    # that if iwd is used, the `80-iwd.link` file contains this random mac
    # address policy as well.
    systemd.network.links."90-random-mac-address" = {
      matchConfig.Type = "ether wlan wwan";
      linkConfig = {
        NamePolicy = "path kernel";
        MACAddressPolicy = "random";
      };
    };

    systemd.network.links."80-iwd" = lib.mkIf config.networking.wireless.iwd.enable {
      linkConfig.MACAddressPolicy = "random";
    };
  };
}
