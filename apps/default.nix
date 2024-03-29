inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs:
  let
    mkApp = script: {
      type = "app";
      program = toString script;
    };
  in
  {
    setup-pam-u2f = mkApp (pkgs.writeShellScript "setup-pam-u2f" ''
      ${pkgs.pam_u2f}/bin/pamu2fcfg -opam://homelab
    '');
    setup-yubikey = mkApp (pkgs.writeShellScript "setup-yubikey" ''
      ${pkgs.yubikey-manager}/bin/ykman openpgp keys set-touch sig cached-fixed
    '');
    flash-kinesis = mkApp (pkgs.writeShellScript "flash-kinesis" ''
      ${pkgs.teensy-loader-cli}/bin/teensy-loader-cli -w -v --mcu=TEENSY40 "${pkgs.kinesis-kint41-jmbaur}/kinesis_kint41_jmbaur.hex"
    '');
  })
  inputs.self.legacyPackages
