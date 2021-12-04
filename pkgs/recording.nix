{ writeShellScriptBin }:
{
  start = writeShellScriptBin "start-recording" ''
    LABEL="WfRecorder"
    sudo modprobe v4l2loopback exclusive_caps=1 card_label=$LABEL
    DEVICE=$(${pkgs.v4l-utils}/bin/v4l2-ctl --list-devices | grep $LABEL -A1 | tail -n1 | sed 's/\s//')
    ${pkgs.wf-recorder}/bin/wf-recorder --muxer=v4l2 --codec=rawvideo --file=$DEVICE -x yuv420p
  '';
  stop = writeShellScriptBin "stop-recording" ''
    sudo modprobe --remove v4l2loopback
  '';
}
