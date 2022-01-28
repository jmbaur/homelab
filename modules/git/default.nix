{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.git;
in
{
  options = {
    custom.git.enable = mkEnableOption "Custom git setup";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.git ];
    environment.etc."gitconfig".text = ''
      [user]
              name = Jared Baur
              email = jaredbaur@fastmail.com

      [alias]
              st = status --short --branch
              di = diff
              br = branch
              co = checkout
              lg = log --graph --decorate --pretty=oneline --abbrev-commit --all

      [pull]
              rebase = false

      [credential]
              helper = store
    '';
  };
}
