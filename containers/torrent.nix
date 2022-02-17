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
  services.transmission = {
    enable = true;
    openRPCPort = true;
    settings = {
      rpc-whitelist = "192.168.0.0/16";
      rpc-bind-address = "0.0.0.0";
      script-torrent-done-filename = "${script}/bin/torrent-done";
      script-torrent-done-enabled = true;
      trash-original-torrent-files = true;
    };
  };

}
