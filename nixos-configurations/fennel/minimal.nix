{
  tinyboot = {
    enable = true;
    board = "kukui-fennel";
  };

  hardware.chromebook.enable = true;
  boot.kernelParams = [ "console=ttyS0,115200" ];

  nixpkgs.hostPlatform = "aarch64-linux";
  powerManagement.cpuFreqGovernor = "ondemand";
}
