{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.i3;
in
{

  options = {
    custom.i3 = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    programs.xss-lock =
      let
        xsecurelock = pkgs.symlinkJoin {
          name = "xsecurelock";
          paths = [ pkgs.xsecurelock ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/xsecurelock \
              --set XSECURELOCK_AUTH_BACKGROUND_COLOR "#1a1a1a" \
              --set XSECURELOCK_AUTH_FOREGROUND_COLOR "#e0e0e0" \
              --set XSECURELOCK_AUTH_WARNING_COLOR "#ff929f" \
              --set XSECURELOCK_DIM_COLOR "#1a1a1a" \
              --set XSECURELOCK_FONT "DejaVu Sans Mono:size=14"
          '';
        };
      in
      {
        enable = true;
        extraOptions = [ "-n" "${xsecurelock}/libexec/xsecurelock/dimmer" "-l" ];
        lockerCommand = ''
          ${xsecurelock}/bin/xsecurelock
        '';
      };

    services.xserver.displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
        Xcursor.theme: Adwaita
      EOF
    '';
    services.xserver.displayManager = {
      defaultSession = "none+i3";
      autoLogin = { enable = true; user = "jared"; };
    };
    services.xserver.windowManager.i3.enable = true;
    services.xserver.enable = true;
    services.xserver.layout = "us";
    services.xserver.xkbOptions = "ctrl:nocaps";
    services.xserver.deviceSection = ''
      Option "TearFree" "true"
    '';
    services.xserver.libinput = {
      enable = true;
      touchpad = {
        accelProfile = "flat";
        tapping = true;
        naturalScrolling = true;
      };
    };
  };

}
