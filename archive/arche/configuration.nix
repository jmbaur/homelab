{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    "${
      builtins.fetchGit {
        url = "https://github.com/NixOS/nixos-hardware.git";
        rev = "03c60a2db286bcd8ecfac9a8739c50626ca0fd8e";
        ref = "master";
      }
    }/lenovo/thinkpad/x13"
    ../../roles/home.nix
    ../../programs/tmux.nix
    ../../programs/psql.nix
    ../../programs/email.nix
    ../../programs/neovim.nix
    ../../roles/common.nix
    ../../roles/desktop.nix
    ../../roles/code.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices.cryptlvm = {
    device = "/dev/disk/by-uuid/4217909d-2845-4b4d-b8ba-05a27a2476b8";
    preLVM = true;
    allowDiscards = true;
  };
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  networking.hostName = "arche";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";
  console.useXkbConfig = true;

  security.pam.services.jared.gnupg.enable = true;
  services.fwupd.enable = true;
  services.udisks2.enable = true;
  services.printing.enable = true;
  services.geoclue2.enable = true;
  services.tailscale.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  sound.enable = true;
  hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = true;

  environment.etc = { gitconfig.source = ../../configs/gitconfig; };

  environment.systemPackages = with pkgs; [
    pulsemixer
    gnupg
    pinentry
    pinentry-gtk2
    nix-prefetch-git
    file
    zip
    unzip
    curl
    wget
    jq
    htop
    pass
    nvme-cli
    ffmpeg-full
    sshping
    w3m
    xsel
    xclip
    glib
    neofetch
    speedtest-cli
    tree
    pstree
    break-time
  ];

  users.users.jared = {
    extraGroups = [ "networkmanager" "video" "wireshark" ];
    shell = pkgs.bash;
  };

  home-manager.users.jared = {
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 60480000;
      maxCacheTtl = 60480000;
      maxCacheTtlSsh = 60480000;
      pinentryFlavor = "gtk2";
    };
    services.gnome-keyring.enable = true;
  };

  systemd.services.batteryThreshold = {
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    description = "Set battery charging thresholds";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.coreutils}/bin/echo 40 > /sys/class/power_supply/BAT0/charge_control_start_threshold && \
          ${pkgs.coreutils}/bin/echo 60 > /sys/class/power_supply/BAT0/charge_control_end_threshold
      '';
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
