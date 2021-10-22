{ config, pkgs, ... }:

let

  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/nixos/nixos-hardware/archive/3aabf78bfcae62f5f99474f2ebbbe418f1c6e54f.tar.gz";
    sha256 = "10g240brgjz7qi20adwajxwqrqb5zxc79ii1mc20fasgqlf2a8sx";
  };

in
{
  imports = [
    "${nixos-hardware}/common/pc/ssd"
    "${nixos-hardware}/lenovo/thinkpad/t495"
    ../../config
    ../../pkgs
    ./hardware-configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fwupd.enable = true;

  hardware.cpu.amd.updateMicrocode = true;

  hardware.bluetooth.enable = true;

  nixpkgs.config.allowUnfree = true;

  custom = {
    alacritty.enable = true;
    git.enable = true;
    gnome = { enable = true; laptop = true; };
    kitty.enable = true;
    neovim.enable = true;
    tmux.enable = true;
    vscode.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices =
    let
      uuid = "d4b7e0c9-1d9e-47d3-b96c-1033c3adca44";
    in
    {
      "${uuid}" = {
        device = "/dev/disk/by-uuid/${uuid}";
        allowDiscards = true;
        preLVM = true;
      };
    };

  networking.hostName = "beetroot";

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  users.users.jared = {
    description = "Jared Baur";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
  };

  environment.variables.HISTCONTROL = "ignoredups";

  environment.systemPackages = with pkgs; [
    age
    bat
    bitwarden
    element-desktop
    fd
    fdroidcl
    firefox
    gimp
    google-chrome
    gosee
    htmlq
    htop
    jq
    libreoffice
    mob
    pa-switch
    proj
    ripgrep
    signal-desktop
    slack
    spotify
    thunderbird
    tokei
    vim
    w3m
    wget
    zoom-us
  ];

  programs.adb.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.libvirtd.enable = true;

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

