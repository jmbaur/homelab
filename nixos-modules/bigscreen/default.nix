{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    ;

  cfg = config.custom.bigscreen;
in
{
  options.custom.bigscreen = {
    enable = mkEnableOption "Plasma Bigscreen";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.kodi.enable;
        message = "custom.bigscreen launches kodi itself, services.kodi must not also be enabled";
      }
    ];

    services.automatic-timezoned.enable = true;
    hardware.bluetooth.enable = true;
    hardware.graphics.enable = true;

    # Kodi's web interface (used for remote apps like Kore)
    networking.firewall = {
      allowedTCPPorts = [ 8080 ];
      allowedUDPPorts = [ 8080 ];
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    services.desktopManager.plasma6.enable = true;
    programs.kde-pim.enable = false;
    services.orca.enable = false;

    # custom.server turns these off, plasma needs them
    fonts.fontconfig.enable = true;
    xdg.autostart.enable = true;
    xdg.mime.enable = true;
    xdg.sounds.enable = true;

    services.displayManager = {
      sessionPackages = [ pkgs.kdePackages.plasma-bigscreen ];
      defaultSession = "plasma-bigscreen-wayland";
      autoLogin = {
        enable = true;
        user = config.users.users.bigscreen.name;
      };
      sddm = {
        enable = true;
        wayland.enable = true;
        autoLogin.relogin = true; # come back up if the session exits
      };
    };

    # Allows the bigscreen input handler to create a uinput device for
    # translating CEC/gamepad input into key events.
    services.udev.packages = [ pkgs.kdePackages.plasma-bigscreen ];

    services.kodi.backend = mkDefault "wayland";

    environment.systemPackages = [
      pkgs.kdePackages.plasma-bigscreen
      config.services.kodi.package
      pkgs.jellyfin-desktop # formerly jellyfin-media-player
      pkgs.vacuum-tube
    ];

    # sddm won't autologin users below minimumUid, which defaults to 1000
    services.displayManager.sddm.autoLogin.minimumUid = config.users.users.bigscreen.uid;

    users.users.bigscreen = {
      isSystemUser = true;
      uid = 900;
      home = "/var/lib/bigscreen";
      createHome = true;
      useDefaultShell = true;
      group = config.users.groups.bigscreen.name;
      extraGroups = [
        "audio"
        "dialout" # needed for pulse-eight CEC adapter
        "input" # needed for uinput
        "video"
      ];
    };
    users.groups.bigscreen = { };
  };
}
