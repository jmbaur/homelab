{ config, pkgs, ... }:
let home-manager = import ./home-manager.nix { ref = "release-21.05"; };
in {
  home-manager.users.jared.xdg.configFile."i3status-rust/config.toml".source =
    ./i3status-laptop.toml;
}
