{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  users.users.jared = {
    isNormalUser = true;
    initialPassword = "helloworld";
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };
  boot.isContainer = true;
  custom.common.enable = true;
  networking = {
    hostName = "dev";
    interfaces.mv-trusted.useDHCP = true;
  };
  services.openssh.enable = true;
}
