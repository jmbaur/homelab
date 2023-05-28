{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ./disko.nix ];
  hardware.bluetooth.enable = true;

  zramSwap.enable = true;

  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];

  # Don't allow for unattended unlocking of the LUKS container when we are
  # booting the "flashfriendly" specialisation.
  specialisation.flashfriendly.configuration.boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = lib.mkForce [ "fido2-device=auto" ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.initrd.availableKernelModules = [ "i915" ];
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.extraInstallCommands = ''
    find /boot/EFI/nixos -type f -name "*.efi" \
      -exec ${pkgs.tinyboot-client}/bin/tbootctl verified-boot sign --verbose --private-key /etc/tboot-privkey --file {} \;
  '';

  hardware.chromebook.enable = true;
  networking.hostName = "beetroot";

  custom = {
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
    users.jared = {
      enable = true;
      passwordFile = config.sops.secrets.jared_password.path;
    };
    remoteBuilders.aarch64builder.enable = false;
    wg-mesh = {
      enable = true;
      dns = true;
      # peers.squash.extraConfig.Endpoint = "squash.home.arpa:51820"; # "vpn.jmbaur.com:51820";
    };
  };

  systemd.network.networks.wg0.linkConfig.ActivationPolicy = "manual";

  nixpkgs.config.allowUnfree = true;

  security.pam.u2f = {
    enable = true;
    cue = true;
    origin = "pam://homelab";
    authFile = config.sops.secrets.pam_u2f_authfile.path;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.wg0 = { };
    secrets.pam_u2f_authfile = { };
    secrets.jared_password.neededForUsers = true;
  };

  programs.adb.enable = true;

  home-manager.users.jared = { config, ... }: {
    services.kanshi = {
      profiles = {
        default = { outputs = [{ criteria = "eDP-1"; }]; };
        docked = {
          outputs = config.services.kanshi.profiles.default.outputs ++ [
            { criteria = "Lenovo Group Limited LEN P24q-20 V306P4GR"; mode = "2560x1440@74.78Hz"; }
          ];
        };
      };
    };
  };

  environment.systemPackages = [ pkgs.tinyboot ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
