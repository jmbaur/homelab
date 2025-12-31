{
  config,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    {
      custom.server = {
        enable = true;
        interfaces.broccoli-0.matchConfig.Path = "platform-xhci-hcd.0.auto-usb-0:1.1:1.0";
      };
      hardware.blackrock.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-1c20000.pcie-pci-0002:01:00.0-nvme-1";
    }
    {
      nix.settings.extra-trusted-users = [ config.users.users.builder.name ];

      # Ensure our build machine doesn't attempt to use itself as a substituter
      nix.settings.substituters = lib.mkForce [ "https://cache.nixos.org" ];
      nix.settings.extra-substituters = lib.mkForce [ ];

      users.users.builder = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdvoVe/aTHTNPIg5xtq4XEKo6PyEa0HkOWoWzvYBoQI kale-hydra"
        ];
      };

      custom.yggdrasil.peers.kale.allowedTCPPorts = [ 22 ];
    }
  ];
}
