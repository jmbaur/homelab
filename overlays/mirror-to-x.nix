{ wf-recorder
, writeShellScriptBin
}:
writeShellScriptBin "mirror-to-x" ''
  export SDL_VIDEODRIVER=x11
  ${wf-recorder}/bin/wf-recorder -c rawvideo -m sdl -f pipe:xwayland-mirror
''
