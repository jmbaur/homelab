{ config, lib, pkgs, ... }: {
  users.users.jared = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles =
      lib.singleton (import ./data/jmbaur-ssh-keys.nix);
  };
}
