{ config, lib, pkgs, ... }: {
  imports = [ <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix> ];
  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ "${builtins.readFile ../../lib/publicSSHKey.txt}" ];
  environment.etc."nixos/configuration.nix".source = ./configuration.nix;
  environment.systemPackage = [ pkgs.raspberrypi-eeprom ];
}
