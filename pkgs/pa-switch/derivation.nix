{ pkgs ? import <nixpkgs> { } }:
pkgs.writeShellScriptBin "pa-switch" ''
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
''
