{ config, ... }: {
  tinyboot.enable = true;
  tinyboot.board = "volteer-elemi";

  hardware.chromebook.enable = true;

  networking.hostName = "cabbage";
  custom.laptop.enable = true;

  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = "powersave";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = "x86_64-linux";
}
