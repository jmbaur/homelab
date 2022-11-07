{ writeShellScriptBin, v4l-utils, ffmpeg-full }:
writeShellScriptBin "v4l-show" ''
  export SDL_VIDEODRIVER=x11
  ${v4l-utils}/bin/v4l2-ctl --list-devices \
    | grep -A1 v4l2loopback | tail -n1 \
    | xargs ${ffmpeg-full}/bin/ffplay
''
