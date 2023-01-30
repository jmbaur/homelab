{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/home".options = [ "noatime" "discard=async" "compress=zstd" ];
  zramSwap.enable = true;

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "fido2-device=auto" ];
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  services.fwupd.enable = true;

  time.timeZone = "America/Los_Angeles";
  networking.hostName = "okra";

  custom.basicNetwork.enable = true;
  custom.basicNetwork.hasWireless = false; # it actually does, but we don't use it
  custom.dev.enable = true;
  custom.gui.enable = true;
  custom.remoteBuilders.aarch64builder.enable = true;
  custom.users.jared.enable = true;

  users.mutableUsers = true;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "rdp" "${pkgs.freerdp}/bin/wlfreerdp /sec:tls /cert:tofu /v:laptop.work.home.arpa -grab-keyboard +auto-reconnect")
    (writeShellScriptBin "work-browser" "${chromium-wayland}/bin/chromium --user-data-dir=$HOME/.config/chromium-work --proxy-server=socks5://localhost:9050")
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
