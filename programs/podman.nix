{ config, pkgs, ... }: {
  home-manager.users.jared.home.file.".config/containers/containers.conf".text =
    ''
      [engine]
      detach_keys = "ctrl-e,ctrl-q"
    '';
}
