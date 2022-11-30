{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  hardware.kukui-fennel14.enable = true;
  zramSwap.enable = true;

  boot.loader.depthcharge = {
    enable = true;
    partition = "/dev/disk/by-partuuid/09957051-883d-5542-8fa8-47d3d5c953de";
  };
  boot.initrd.systemd.enable = true;

  networking.hostName = "fennel";
  networking.useNetworkd = true;
  networking.wireless.enable = true;

  custom.gui.enable = true;
  custom.dev.enable = true;
  custom.remoteBuilders.aarch64builder.enable = true;
  custom.users.jared.enable = true;
  users.mutableUsers = true;

  environment.systemPackages = with pkgs; [ chromium-wayland firefox ];

  system.stateVersion = "22.11";
}
