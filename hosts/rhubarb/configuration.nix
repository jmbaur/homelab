{ config, lib, pkgs, ... }: {
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

  boot.kernelPackages = pkgs.linuxPackages_5_18;

  networking = {
    hostName = "rhubarb";
    useNetworkd = true;
  };
  services.resolved.enable = true;

  systemd.network.networks.wired = {
    name = "eth*";
    DHCP = "yes";
    dhcpV4Config.ClientIdentifier = "mac";
  };

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "dialout" "wheel" ];
    packages = with pkgs; [ tmux picocom ];
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };

  system.stateVersion = "22.11";
}
