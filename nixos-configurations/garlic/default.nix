{ ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # python -m http.server
  networking.firewall.allowedTCPPorts = [ 8000 ];

  custom.dev.enable = true;
  custom.users.jared.enable = true;
}
