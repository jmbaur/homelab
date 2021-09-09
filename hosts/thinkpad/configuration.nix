{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./t470p.nix ../common.nix ];
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/jared/Projects/nixos-configs/hosts/thinkpad/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_5_13;

  networking.hostName = "thinkpad";
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "ctrl:nocaps";
    libinput = {
      enable = true;
      touchpad.tapping = true;
      touchpad.naturalScrolling = true;
      touchpad.disableWhileTyping = true;
    };
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
    videoDrivers = [ "modesetting" "nvidia" ];
  };

  hardware.nvidia.prime = {
    offload.enable = true;
    intelBusId = "PCI:00:02:0";
    nvidiaBusId = "PCI:02:00:0";
  };

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  environment.systemPackages = with pkgs; [
    # specific to the laptop
    acpi
    geteltorito
    brightnessctl

    xmobar
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.dbus.packages = [ pkgs.gcr ];

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}

