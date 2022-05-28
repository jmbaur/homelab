{ lib, ... }: {
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.nixos.openssh.authorizedKeys.keyFiles =
    [ (import ./data/jmbaur-ssh-keys.nix) ];
}
