{ config, pkgs, ... }:

let

  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/nixos/nixos-hardware/archive/3aabf78bfcae62f5f99474f2ebbbe418f1c6e54f.tar.gz";
    sha256 = "10g240brgjz7qi20adwajxwqrqb5zxc79ii1mc20fasgqlf2a8sx";
  };

in
{
  imports =
    [
      "${nixos-hardware}/common/pc/ssd"
      "${nixos-hardware}/common/cpu/amd"
      ../../config
      ../../pkgs
      ../../lib/common.nix
      ./hardware-configuration.nix
    ];

  security.tpm2.enable = true;

  boot.plymouth.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "okra";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  custom = {
    awesome.enable = true;
    ddcci.enable = true;
    git.enable = true;
    kitty.enable = true;
    neovim.enable = true;
    pipewire.enable = true;
    tmux.enable = true;
    vscode.enable = true;
  };

  boot.initrd.luks.devices =
    let
      uuid = "b9b68eee-c3b9-48f0-9b8c-8c31fce4f185";
    in
    {
      "${uuid}" = {
        allowDiscards = true;
        preLVM = true;
        device = "/dev/disk/by-uuid/${uuid}";
      };
    };

  nixpkgs.config.allowUnfree = true;

  hardware.cpu.amd.updateMicrocode = true;

  services.fwupd.enable = true;
  services.autorandr.enable = true;
  services.clipmenu.enable = true;
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.syncthing = {
    enable = false;
    user = "jared";
    group = "users";
    dataDir = "/home/jared";
    configDir = "/home/jared/.config/syncthing";
    openDefaultPorts = true;
    declarative.overrideFolders = false;
    declarative.overrideDevices = true;
  };

  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
