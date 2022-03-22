{ config, lib, pkgs, ... }:
let
  cfg = config.custom.laptop;
in
{
  options.custom.laptop.enable = lib.mkEnableOption "Enable laptop configs";
  config = lib.mkIf cfg.enable {
    xsession.initExtra = ''
      ${pkgs.autorandr}/bin/autorandr --change
    '';
    xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault {
      "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
      "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
    };

    services.xcape.enable = true;

    services.poweralertd.enable = true;

    programs.i3status = {
      enable = true;
      enableDefault = true;
    };

    programs.autorandr =
      let
        DP2-3 = "00ffffffffffff0030aef561524734502f1e0104a5351e783ee235a75449a2250c5054bdef0081809500b300d1c0d100714f818f0101565e00a0a0a02950302035000f282100001a000000ff0056333036503447520a20202020000000fd00304c1e721e010a202020202020000000fc004c454e20503234712d32300a20015302031cf1490102030413901f1211230907078301000065030c001000011d007251d01e206e2855000f282100001ecc7400a0a0a01e50302035000f282100001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009f";
        eDP1 = "00ffffffffffff0030e446040000000000170104951f1178ea4575a05b5592270c5054000000010101010101010101010101010101012e3680a070381f403020350035ae1000001a000000000000000000000000000000000000000000fe004c4720446973706c61790a2020000000fe004c503134305746332d53504c3100a8";
      in
      {
        enable = true;
        profiles.docked = {
          fingerprint = { inherit DP2-3 eDP1; };
          config.eDP1.enable = false;
          config.DP2-3 = {
            enable = true;
            primary = true;
            mode = "2560x1440";
            rate = "74.78";
          };
        };
        profiles.laptop = {
          fingerprint = { inherit eDP1; };
          config.eDP1 = {
            enable = true;
            primary = true;
            mode = "1920x1080";
            rate = "60.02";
          };
        };
      };
  };
}
