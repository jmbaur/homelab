{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  hardware.bluetooth.enable = true;

  zramSwap.enable = true;

  boot = {
    initrd = {
      systemd.enable = true;
      luks.devices."cryptroot".crypttabExtraOpts = [ "fido2-device=auto" ];
    };
    kernelPackages = pkgs.linuxPackages_6_0;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  time.timeZone = "America/Los_Angeles";

  networking = {
    useDHCP = false;
    hostName = "carrot";
  };
  services.resolved.enable = true;

  custom = {
    common.enable = true;
    dev.enable = true;
    gui.enable = true;
    gui.variant = "sway";
    laptop.enable = true;
    users.jared.enable = true;
    remoteBuilders.aarch64builder.enable = true;
  };

  home-manager.users.jared = { systemConfig, config, pkgs, ... }: {
    programs.git = {
      userEmail = "jaredbaur@fastmail.com";
      userName = systemConfig.users.users.jared.description;
      extraConfig = {
        commit.gpgSign = true;
        gpg.format = "ssh";
        gpg.ssh.defaultKeyCommand = "ssh-add -L";
        gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowedSignersFile" ''
          ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
          ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
        '');
        user.signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
      };
    };
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "*.mgmt.home.arpa".forwardAgent = true;
        work = {
          user = "jbaur";
          hostname = "dev.work.home.arpa";
          dynamicForwards = [{ port = 9050; }];
          localForwards = [
            { bind.port = 1025; host.address = "localhost"; host.port = 1025; }
            { bind.port = 8000; host.address = "localhost"; host.port = 8000; }
          ];
        };
      };
    };

    home.packages = with pkgs; [
      age-plugin-yubikey
      bitwarden
      brave-wayland
      discord-wayland
      element-desktop-wayland
      firefox-wayland
      freerdp
      google-chrome-wayland
      outlook-webapp
      signal-desktop-wayland
      slack-wayland
      spotify
      teams-webapp
    ];
  };

  nixpkgs.config.allowUnfree = true;

  services.fwupd.enable = true;

  security.pam.u2f = {
    enable = false;
    cue = true;
    origin = "pam://homelab";
    authFile = config.sops.secrets.pam_u2f_authfile.path;
  };

  # sops = {
  #   defaultSopsFile = ./secrets.yaml;
  #   secrets.pam_u2f_authfile = { };
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
