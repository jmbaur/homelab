{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  boot.loader.depthcharge = {
    enable = true;
    partition = "/dev/disk/by-partuuid/09957051-883d-5542-8fa8-47d3d5c953de";
  };
  hardware.kukui-fennel14.enable = true;
  zramSwap.enable = true;

  networking.hostName = "fennel";
  system.stateVersion = "22.11";

  custom.gui.enable = true;
  custom.dev.enable = true;
  custom.users.jared.enable = true;
  users.users.jared.password = "dontpwnme";

  environment.systemPackages = with pkgs; [ firefox ];
}
