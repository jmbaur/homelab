{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ (import ../pubSshKey.nix) ];

  networking.hostName = "kale";

  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2.useDHCP = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.openssh.enable = true;
  services.syncthing = {
    enable = true;
    configDir = "/data/syncthing/.config/syncthing";
    dataDir = "/data/syncthing";
    openDefaultPorts = true;
    declarative.overrideFolders = true;
    declarative.overrideDevices = true;
    declarative.folders = {
      documents = {
        path = "/data/syncthing/Documents";
        versioning = {
          type = "simple";
          params = { keep = "10"; };
        };
      };
      downloads = {
        path = "/data/syncthing/Downloads";
        versioning = {
          type = "simple";
          params = { keep = "10"; };
        };
      };
      pictures = {
        path = "/data/syncthing/Pictures";
        versioning = {
          type = "simple";
          params = { keep = "10"; };
        };
      };
      music = {
        path = "/data/syncthing/Music";
        versioning = {
          type = "simple";
          params = { keep = "10"; };
        };
      };
      videos = {
        path = "/data/syncthing/Videos";
        versioning = {
          type = "simple";
          params = { keep = "10"; };
        };
      };
    };
    declarative.devices = { };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 8384 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
