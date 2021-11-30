{ config, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  nixpkgs.overlays = [
    (self: super: {
      install-nixos = super.writeShellScriptBin "install-nixos" ''
        echo TODO
      '';
    })
  ];
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../lib/yubikeySshKey.txt)
  ];
  environment.systemPackages = with pkgs; [
    gnupg
    install-nixos
    pinentry
    pinentry-curses
  ];
}
