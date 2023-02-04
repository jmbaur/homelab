{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "squash";
  networking.useNetworkd = true;
  hardware.clearfog-a38x.enable = true;
  custom = {
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
  };
  zramSwap.enable = true;
  system.stateVersion = "23.05";
}
