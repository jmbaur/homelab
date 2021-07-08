{ config, pkgs, ... }: {
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
    }))
  ];
  environment.systemPackages = [ pkgs.emacsGcc ];
  home-manager.users.jared = {
    services.emacs.enable = true;
    services.emacs.client.enable = true;
    services.emacs.client.arguments = [ "-nc" ];
  };
}
