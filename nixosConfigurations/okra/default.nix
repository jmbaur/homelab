{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/home".options = [ "noatime" "discard=async" "compress=zstd" ];

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "okra";

  time.timeZone = "America/Los_Angeles";

  custom.dev.enable = true;
  custom.gui.enable = true;
  custom.users.jared.enable = true;
  custom.remoteBuilders.aarch64builder.enable = true;

  users.mutableUsers = true;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "rdp" "${pkgs.freerdp}/bin/wlfreerdp /sec:tls /cert:tofu -grab-keyboard /v:laptop.work.home.arpa")
    bitwarden
    chromium-wayland
    firefox
    librewolf
    outlook-webapp
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
