{ config, pkgs, ... }:
let
  install-nixos = pkgs.writeShellScriptBin "install-nixos" ''
    hello world
  '';
in
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../lib/publicSSHKey.txt)
  ];
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry
    pinentry-curses
  ] ++ [ install-nixos ];
}
