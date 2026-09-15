_: {
  hardware.nvidia-jetpack = {
    enable = true;
    majorVersion = "7";
    som = "thor-agx";
    carrierBoard = "devkit";
  };

  # TODO(jared): doesn't cross
  # hardware.graphics.enable = true;

  users.users.root.initialPassword = "";
}
