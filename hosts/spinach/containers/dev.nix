{ config, lib, pkgs, ... }: {
  imports = [ ../../../lib/nix-unstable.nix ../../../config ];

  nixpkgs.config.allowUnfree = true;

  custom = {
    git.enable = true;
    neovim.enable = true;
    tmux.enable = true;
  };

  networking.hostName = "dev";
  networking.interfaces.mv-eno2.useDHCP = true;

  programs.mosh.enable = true;

  environment.systemPackages = with pkgs; [
    bind
    buildah
    git
    gotop
    htop
    mosh
    neovim
    skopeo
    tmux
    wget
  ];

  services.openssh = { enable = true; ports = [ 2222 ]; };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    containers = {
      enable = true;
      containersConf.settings = {
        containers.keyring = false; # TODO(jared): don't do this
        engine.detach_keys = "ctrl-q,ctrl-e";
      };
    };
  };

  users = {
    mutableUsers = false;
    users.jared = {
      isNormalUser = true;
      initialPassword = "helloworld";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = builtins.filter
        (str: builtins.stringLength str != 0)
        (lib.splitString "\n" (builtins.readFile ../../../lib/ssh_keys.txt));
    };
  };
}
