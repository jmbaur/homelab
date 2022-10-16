{ config, pkgs, ... }: {
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  home-manager.users.jared = { systemConfig, ... }: {
    programs.git = {
      userEmail = "jaredbaur@fastmail.com";
      userName = systemConfig.users.users.jared.description;
    };
  };

  hardware.lx2k.enable = true;

  age.secrets.wg-public-kale = {
    mode = "0640";
    group = config.users.groups.systemd-network.name;
    file = ../../secrets/wg-public-kale.age;
  };

  custom = {
    common.enable = true;
    users.jared.enable = true;
    cross-compiled.enable = true;
    deployee = {
      enable = true;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMF97KbhWOOJzIS/pbf0FHgtx4jVQI8BGFUssKr8itTa root@okra"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcY6NWQGE4zHXOmWTW5kT/S2vQsi79ILzhbtR1GPxho root@carrot"
      ];
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    remoteBoot = {
      enable = true;
      authorizedKeyFiles = config.custom.deployee.authorizedKeyFiles;
    };
    wgWwwPeer.enable = true;
  };

  services.runner = {
    enable = true;
    runs = {
      runner-nix = {
        environment.RUST_LOG = "debug";
        listenAddresses = [ "8000" ];
        adapter = "github";
        command = "${pkgs.nix}/bin/nix build github:jmbaur/runner-nix#default --no-link --extra-experimental-features nix-command --extra-experimental-features flakes --print-build-logs --rebuild";
      };
      artichoke = {
        environment.RUST_LOG = "debug";
        listenAddresses = [ "8001" ];
        adapter = "github";
        command = "${pkgs.nix}/bin/nix build github:jmbaur/homelab#nixosConfigurations.artichoke.config.system.build.toplevel --no-link --extra-experimental-features nix-command --extra-experimental-features flakes --print-build-logs --rebuild";
      };
    };
  };

  services.journald.enableHttpGateway = true;
  services.prometheus.exporters = {
    node = {
      enable = true;
      openFirewall = false;
      enabledCollectors = [ "ethtool" "network_route" "systemd" ];
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
