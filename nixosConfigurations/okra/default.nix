{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/home".options = [ "noatime" "discard=async" "compress=zstd" ];
  zramSwap.enable = true;

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  time.timeZone = "America/Los_Angeles";
  networking = {
    hostName = "okra";
    useDHCP = false;
    useNetworkd = true;
  };
  systemd.network.networks = {
    wired = {
      name = "en*";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 1024;
      ipv6AcceptRAConfig.RouteMetric = 1024;
      networkConfig.IPv6PrivacyExtensions = "kernel";
    };
  };

  custom.dev.enable = true;
  custom.gui.enable = true;
  custom.users.jared.enable = true;
  custom.remoteBuilders.aarch64builder.enable = true;

  users.mutableUsers = true;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "work-browser" "${chromium-wayland}/bin/chromium --user-data-dir=$HOME/.config/chromium-work --proxy-server=socks5://localhost:9050")
    (writeShellScriptBin "rdp" "${pkgs.freerdp}/bin/wlfreerdp /sec:tls /cert:tofu /v:laptop.work.home.arpa -grab-keyboard +auto-reconnect")
    age-plugin-yubikey
    bitwarden
    chromium-wayland
    firefox
    librewolf
    outlook-webapp
    signal-desktop-wayland
    slack-wayland
    spotify
    teams-webapp
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
