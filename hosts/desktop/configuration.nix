{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/jared/Projects/nixos-configs/hosts/thinkpad/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_5_13;
  boot.kernelModules = [ "i2c-dev" ];

  networking.hostName = "desktop";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    layout = "us";
    enable = true;
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        i3lock
        i3status-rust
        dmenu
      ];
      extraSessionCommands = ''
        xsetroot -solid black
      '';
    };
  };

  security.sudo.wheelNeedsPassword = false;
  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adbusers" ];
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ nvme-cli ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.xss-lock = {
    enable = true;
    lockerCommand = ''
      ${pkgs.i3lock}/bin/i3lock -c 000000
    '';
  };

  # List services that you want to enable:
  services.udev.extraRules = ''KERNEL=="i2c-[0-9]*", GROUP+="users"'';

  services.dbus.packages = [ pkgs.gcr ];
  services.gnome.gnome-keyring.enable = true;

  services.pcscd.enable = false;
  services.udev.packages = with pkgs; [ yubikey-personalization ];

  location.latitude = 33.0;
  location.longitude = -118.0;
  services.redshift.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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
