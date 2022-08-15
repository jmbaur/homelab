{ config, pkgs, ... }: {
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.mutableUsers = false;
  users.users.jared = {
    description = "Jared Baur";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };
  home-manager.users.jared = { systemConfig, ... }: {
    programs.git = {
      userEmail = "jaredbaur@fastmail.com";
      userName = systemConfig.users.users.jared.description;
    };
  };

  hardware.lx2k.enable = true;

  custom = {
    common.enable = true;
    dev.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
        ../../data/deployer-ssh-keys.txt
      ];
    };
    remoteBoot = {
      enable = true;
      authorizedKeyFiles = config.custom.deployee.authorizedKeyFiles;
    };
  };

  services.runner = {
    enable = true;
    runs.hello = {
      adapter = "none";
      command = "${pkgs.nix}/bin/nix build nixpkgs#hello --extra-experimental-features nix-command --extra-experimental-features flakes --print-build-logs --rebuild";
    };
  };

  services.prometheus.exporters = {
    node = {
      enable = true;
      openFirewall = true;
      enabledCollectors = [ "ethtool" "network_route" "systemd" ];
    };
    smartctl = {
      enable = true;
      openFirewall = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
