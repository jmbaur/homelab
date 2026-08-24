{
  lib,
  pkgs,
  ...
}:

{
  hardware.keyboard = {
    qmk.enable = true;
    zsa.enable = true;
  };

  services.udev.extraRules =
    # https://www.pjrc.com/teensy/00-teensy.rules
    ''
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_PORT_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789a]*", ENV{MTP_NO_PROBE}="1"
      KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", TAG+="uaccess", RUN:="${lib.getExe' pkgs.coreutils-full "stty"} -F /dev/%k raw -echo"
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", TAG+="uaccess"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", TAG+="uaccess"
      KERNEL=="hidraw*", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="013*", TAG+="uaccess"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="013*", TAG+="uaccess"
    ''
    +
    # Recommended udev rules from bastard keyboards
    # https://docs.bastardkb.com/help/troubleshooting.html#custom-udev-rules
    ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
}
