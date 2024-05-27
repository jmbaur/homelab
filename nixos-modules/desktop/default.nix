{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;
in
{
  options.custom.desktop.enable = lib.mkEnableOption "desktop";

  config = lib.mkIf cfg.enable {
    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    # Add a default browser to use
    programs.firefox = {
      enable = true;
      # Allow users to override preferences set here
      preferencesStatus = "user";
      # Looks better with KDE plasma
      preferences."browser.tabs.inTitlebar" = 0;
    };

    networking.networkmanager = {
      # TODO(jared): this should be enabled by plasma6 module?
      enable = true;
      wifi.backend = "iwd";
    };
    networking.wireless.iwd.enable = true;

    # Doesn't cross-compile
    services.fwupd.enable = pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform;

    hardware.bluetooth.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    services.printing.enable = true;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;
  };
}
