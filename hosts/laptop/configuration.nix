{ config, pkgs, ... }:

let
  nixos-hardware =
    builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; };
in {
  imports = [
    ./hardware-configuration.nix
    "${nixos-hardware}/lenovo/thinkpad"
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/gpu/nvidia.nix"
    "${nixos-hardware}/common/pc/laptop/acpi_call.nix"
    ../common.nix
  ];
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/jared/Projects/nixos-configs/hosts/laptop/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_5_13;

  networking.hostName = "laptop";
  networking.networkmanager.enable = true;

  services.xserver = {
    enable = true;
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

  environment.systemPackages = with pkgs; [ geteltorito brightnessctl xmobar ];

  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.dbus.packages = [ pkgs.gcr ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
