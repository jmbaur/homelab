{ lib, ... }:
with lib;
{
  options.custom.dev = {
    enable = mkEnableOption "dev setup";
    languages = {
      all = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable support for all languages
        '';
      };
    } // lib.listToAttrs (map (lang: lib.nameValuePair lang (mkEnableOption lang)) [
      "go"
      "lua"
      "nix"
      "python"
      "rust"
      "typescript"
      "zig"
    ]);
  };
}
