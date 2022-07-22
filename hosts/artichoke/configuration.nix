{ config, lib, pkgs, ... }: {
  hardware.cn913x.enable = true;

  custom = {
    common.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
        ../../data/deployer-ssh-keys.txt
      ];
    };
  };

  zramSwap.enable = true;

  networking = {
    hostName = "artichoke";
    useDHCP = false;
    useNetworkd = true;
  };

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };

  system.stateVersion = "22.11";
}
