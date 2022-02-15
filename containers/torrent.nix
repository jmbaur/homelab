{ config, lib, pkgs, ... }:
let
  script = pkgs.writeShellApplication {
    name = "torrent-done";
    runtimeInputs = [ ];
    text = ''
      env
      echo "$@"
    '';
  };
in
{
  networking.firewall.allowedTCPPorts = [ 9091 ];
  services.transmission = {
    enable = true;
    settings = {
      script-torrent-done-filename = "${script}/bin/torrent-done";
      script-torrent-done-enabled = true;
      trash-original-torrent-files = true;
    };
  };

}
