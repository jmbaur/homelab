{ config, pkgs, ... }: {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKU/J9T/6BwzloIiXP5wCkgkJbSl5B3z+c6Z/J3baa/u"
  ];
}
