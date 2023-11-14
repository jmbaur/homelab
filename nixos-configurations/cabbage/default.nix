{ pkgs, inputs, ... }: {
  imports = [ ./hardware.nix ];

  system.build.installer = (pkgs.nixos ({
    imports = [ inputs.self.nixosModules.default ./hardware.nix ];
    custom.tinyboot-installer.enable = true;
  })).config.system.build.diskImage;
}
