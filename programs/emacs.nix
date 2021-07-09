{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.emacs ];
  home-manager.users.jared = {
    services.emacs.enable = true;
    services.emacs.client.enable = true;
    services.emacs.client.arguments = [ "-nc" ];
  };
}
