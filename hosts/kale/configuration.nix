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

  services.openssh.enable = true;
  services.syncthing = {
    enable = true;
    configDir = "/data/syncthing/.config/syncthing";
    dataDir = "/data/syncthing";
    openDefaultPorts = true;
    declarative = {
      overrideFolders = true;
      overrideDevices = true;
      devices = {
        okra.id =
          "E6ANVH5-N55GABM-ND5DCYD-PAFN3UU-KOILXIQ-HKVIANN-R5K3HYF-O4BMWQT";
      };
      folders = {
        Desktop = {
          devices = [ "okra" ];
          path = "/data/syncthing/Desktop";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Documents = {
          devices = [ "okra" ];
          path = "/data/syncthing/Documents";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Downloads = {
          devices = [ "okra" ];
          path = "/data/syncthing/Downloads";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Pictures = {
          devices = [ "okra" ];
          path = "/data/syncthing/Pictures";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Music = {
          devices = [ "okra" ];
          path = "/data/syncthing/Music";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Videos = {
          devices = [ "okra" ];
          path = "/data/syncthing/Videos";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
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
