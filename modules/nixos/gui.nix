{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
with lib;
{
  options.custom.gui.enable = mkEnableOption "GUI config";
  config = mkIf cfg.enable {
    hardware.pulseaudio.enable = mkForce false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    fonts.fontconfig.enable = true;
    fonts.fonts = [ pkgs.jetbrains-mono ];

    location.provider = "geoclue2";

    environment.systemPackages = with pkgs; [
      ffmpeg-full
      mpv
      pulsemixer
      obs-studio
      wl-clipboard
      xdg-utils
    ];

    services.dbus.enable = true;
    xdg.portal.enable = true;

    programs.ssh.startAgent = true;

    services.avahi.enable = true;
    services.pcscd.enable = true;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    services.upower.enable = true;
    services.udisks2.enable = true;

    services.greetd = {
      enable = true;
      settings.default_session.command = "${pkgs.greetd.greetd}/bin/agreety --cmd 'systemd-cat --identifier=sway sway'";
    };
    programs.wshowkeys.enable = true;
    environment.variables = {
      inherit (pkgs.callPackage ../shared/bemenu.nix { }) BEMENU_OPTS;
    };

    xdg.portal.wlr.enable = true;

    boot = {
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      kernelModules = [ "v4l2loopback" ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1 card_label=VirtualVideoDevice
      '';
    };

    programs.sway = {
      enable = true;
      extraPackages = with pkgs; [
        bemenu
        brightnessctl
        clipman
        gnome-themes-extra
        grim
        imv
        mirror-to-x
        qt5.qtwayland
        slurp
        v4l-show
        v4l-utils
        wev
        wf-recorder
        wlr-randr
      ];
      inherit (import ../shared/sway.nix) extraSessionCommands wrapperFeatures;
    };
  };
}
