{ config, pkgs, ... }:
let
  audio = pkgs.writeShellScriptBin "audio" ''
    case $1 in
    "sink")
      pactl set-default-sink $(pactl list sinks short | awk '{print $2}' | fzf)
      ;;
    "source")
      pactl set-default-source $(pactl list sources short | awk '{print $2}' | fzf | awk '{print $1}')
      ;;
    *)
      echo "Argument must be 'sink' or 'source'"
      exit 1
      ;;
    esac
  '';
in { environment.systemPackages = [ audio ]; }
