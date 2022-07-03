{ pkgs, lib, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_5_18;
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.nixos.openssh.authorizedKeys.keyFiles =
    [ (import ./data/jmbaur-ssh-keys.nix) ];
}
