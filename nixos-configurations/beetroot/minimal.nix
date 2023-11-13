{ config, ... }: {
  tinyboot = {
    enable = true;
    board = "brya-banshee";
  };

  hardware.chromebook.enable = true;

  boot.kernelParams = [ "console=ttyS0,115200" ];

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  powerManagement.cpuFreqGovernor = "powersave";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
