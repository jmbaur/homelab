{ pkgs, ... }:
{
  nixpkgs.overlays = [

    (import ./alacritty.nix)
    (import ./chromium.nix)
    (import ./fdroidcl.nix)
    (import ./foot.nix)
    (import ./git-get.nix)
    (import ./gosee.nix)
    (import ./i3status-rust)
    (import ./kanshi.nix)
    (import ./kitty.nix)
    (import ./mako.nix)
    (import ./slack.nix)
    (import ./zig.nix)
    (import ./zls.nix)

    (self: super: {
      htmlq = super.callPackage ./htmlq.nix { };
    })
    (self: super: {
      nix-direnv = super.nix-direnv.override { enableFlakes = true; };
    })

    (self: super: {
      bat = super.bat.overrideAttrs (old: {
        postInstall = ''
          wrapProgram $out/bin/bat --add-flags "--theme=gruvbox-dark"
        '';
      });
    })

    (self: super: {
      vscode-with-extensions = super.vscode-with-extensions.override {
        vscodeExtensions = with super.vscode-extensions; [
          ms-vsliveshare.vsliveshare
          vscodevim.vim
        ];
      };
    })

    (self: super: {
      start-recording = super.writeShellScriptBin "start-recording" ''
        LABEL="WfRecorder"
        sudo modprobe v4l2loopback exclusive_caps=1 card_label=$LABEL
        DEVICE=$(${pkgs.v4l-utils}/bin/v4l2-ctl --list-devices | grep $LABEL -A1 | tail -n1 | sed 's/\s//')
        ${pkgs.wf-recorder}/bin/wf-recorder --muxer=v4l2 --codec=rawvideo --file=$DEVICE -x yuv420p
      '';
      stop-recording = super.writeShellScriptBin "stop-recording" ''
        sudo modprobe --remove v4l2loopback
      '';
    })
    (self: super: {
      p = super.writeShellScriptBin "p" ''
        usage() {
          echo "usage: p <dir>"
          echo
          echo "The default projects directory is \$HOME/Projects. This can be"
          echo "overridden by setting the \$PROJ_DIR environment variable."
        }
        DIR=''${PROJ_DIR:-''${HOME}/Projects}
        SEARCH=$1
        if [ -z "''${SEARCH}" ]; then
          usage
          exit 1
        fi
        if [ ! -d $DIR ]; then
          echo "Cannot find project directory"
          exit 2
        fi
        DIRS=($(${super.fd}/bin/fd -t d -H ^.git$ $DIR | xargs dirname | tr " " "\n"))
        IDX=$(echo "''${DIRS[@]}" | xargs basename -a | grep -n ".*''${SEARCH}.*" | cut -d ":" -f 1 | head -n 1)
        if [ -z "$IDX" ]; then
          echo "Cannot find project with search term ''${SEARCH}"
          exit 3
        fi
        PROJ=''${DIRS[$IDX - 1]}
        PROJECT_NAME=$(basename $PROJ)
        TMUX_SESSION_NAME=''${PROJECT_NAME:0:7}
        ${super.tmux}/bin/tmux new-session -d -c ''${PROJ} -s $TMUX_SESSION_NAME
        if [ -n "$TMUX" ]; then
          ${super.tmux}/bin/tmux switch-client -t $TMUX_SESSION_NAME
        else
          ${super.tmux}/bin/tmux attach-session -t $TMUX_SESSION_NAME
        fi
      '';
    })
    (self: super: {
      pa-switch = super.writeShellScriptBin "pa-switch" ''
        DEVICE_TYPE=$1
        if [[ ''${DEVICE_TYPE} != "source" && ''${DEVICE_TYPE} != "sink" ]]; then
          echo "Usage:"
          echo -e "\tpa-switch sink|source"
          exit 1
        fi

        CURRENT_DEVICE=$(pacmd stat | grep "Default ''${DEVICE_TYPE} name" | awk -F ": " '{print $2}')
        DEVICES=$(pactl list "''${DEVICE_TYPE}"s | grep -e "Name: " -e "device.class")

        POTENTIAL_DEVICES=""
        while read -r NAME; do
          read -r CLASS

          PP_NAME=$(echo "''${NAME}" | awk -F ": " '{print $2}')

          if [[ ''${CLASS} == *"monitor"* ]]; then
            echo "Skipping device class of \"monitor\": ''${PP_NAME}"
            continue
          fi

          if [[ ''${PP_NAME} == "''${CURRENT_DEVICE}" ]]; then
            echo "Already using ''${DEVICE_TYPE}: ''${PP_NAME}"
            POTENTIAL_DEVICES+="!,"
            continue
          fi

          POTENTIAL_DEVICES+="''${PP_NAME},"
        done <<<"''${DEVICES}"

        NEXT_DEVICE=$(echo "''${POTENTIAL_DEVICES}" | sed -e 's/.*\!\,//' -e 's/\,.*//')
        FIRST_DEVICE=$(echo "''${POTENTIAL_DEVICES}" | cut -d'!' -f 1 | cut -d',' -f 1) # TODO(jared): couldn't figure out how to do this with sed

        if [[ ''${NEXT_DEVICE} != "" ]]; then
          echo "Setting device to ''${NEXT_DEVICE}"
          pactl set-default-"''${DEVICE_TYPE}" "''${NEXT_DEVICE}"
        elif [[ ''${FIRST_DEVICE} != "" ]]; then
          echo "Setting device to ''${FIRST_DEVICE}"
          pactl set-default-"''${DEVICE_TYPE}" "''${FIRST_DEVICE}"
        else
          echo "Could not find device to switch to"
          exit 1
        fi
      '';
    })

  ];

}
