{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "okra";
  networking.wireless.enable = true;

  time.timeZone = "America/Los_Angeles";

  custom.common.enable = true;
  custom.deploy.enable = true;
  custom.gui.enable = true;
  custom.jared.enable = true;
  custom.sound.enable = true;

  environment.systemPackages = with pkgs; [ firefox google-chrome ];
  users.users.jared.hashedPassword = "$6$MCUX2IpSO6QN9nNc$Xpk.2K6pVL3FxOoFC/Mg5vA4BpgyNDvhQ9cWJXRA.CFTTJrh.W5RChgpZUI7pflSlCXfmdJhnsrHisezu6k6j/";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
