{ config, pkgs, ... }:

let home-manager = import ./home-manager.nix { ref = "release-21.05"; };
in {
  imports = [ ./hardware-configuration.nix ../common.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "i2c-dev" ];

  networking.hostName = "okra";

  environment.systemPackages = with pkgs; [ nvme-cli ];

  services.udev.extraRules = ''KERNEL=="i2c-[0-9]*", GROUP+="users"'';
  services.openssh.enable = true;
  services.xserver.enable = true;

  home-manager.users.jared.xsession.windowManager.i3.config.bars = [{
    statusCommand =
      "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-okra.toml";
    position = "top";
    fonts = {
      names = [ "DejaVu Sans Mono" ];
      size = 10.0;
    };
  }];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
