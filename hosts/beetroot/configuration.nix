{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./jared-home.nix
  ];

  hardware.bluetooth.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelParams = [ "quiet" ];
  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  networking.hostName = "beetroot";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  custom.common.enable = true;
  custom.desktop.enable = true;
  custom.virtualisation.enable = true;

  users.mutableUsers = lib.mkForce true;
  users.users.jared = {
    isNormalUser = true;
    initialPassword = "helloworld";
    extraGroups = [
      "adbusers"
      "dialout"
      "libvirtd"
      "networkmanager"
      "wheel"
      "wireshark"
    ];
  };
  services.snapper.configs.home = {
    subvolume = "/home";
    extraConfig = ''
      TIMELINE_CREATE=yes
      TIMELINE_CLEANUP=yes
    '';
  };

  nixpkgs.config.allowUnfree = true;

  programs.adb.enable = true;
  programs.mtr.enable = true;
  programs.ssh.startAgent = true;
  programs.wireshark.enable = true;

  services.avahi.enable = true;
  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;
  services.pcscd.enable = false;
  services.power-profiles-daemon.enable = true;
  services.printing.enable = true;
  services.upower.enable = true;

  networking.firewall.enable = true;

  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
