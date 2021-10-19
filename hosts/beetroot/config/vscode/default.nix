{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.vscode;
in
{
  options = {
    custom.vscode = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable custom bundle of vscode and extensions.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (vscode-with-extensions.override {
        vscodeExtensions = with vscode-extensions; [
          ms-vsliveshare.vsliveshare
          vscodevim.vim
        ];
      })
    ];
  };
}
