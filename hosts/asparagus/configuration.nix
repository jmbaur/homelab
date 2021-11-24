{ config, pkgs, ... }: {
  imports = [ ./secrets.nix ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "net.ifnames=0" ];

  networking.hostName = "asparagus";
  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
  };

  time.timeZone = "America/Los_Angeles";

  networking.interfaces.eth0.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

  services.avahi.enable = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.userServices = true;

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "ctrl:nocaps";
    displayManager.autoLogin = {
      enable = true;
      user = "kodi";
    };
    desktopManager.kodi.enable = true;
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  users = {
    mutableUsers = false;
    users.kodi.isNormalUser = true;
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
  networking.firewall.allowedUDPPorts = [ 8080 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
