{ config, lib, pkgs, ... }: {
  users.users.jared = {
    openssh.authorizedKeys.keyFiles =
      lib.singleton (import ./data/jmbaur-ssh-keys.nix);
  };
}
