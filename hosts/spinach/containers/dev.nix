{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    bind
    git
    htop
    neovim
    podman
    tmux
    wget
  ];
  services.openssh = {
    enable = false;
    ports = [ 2222 ];
  };
  # networking.interfaces.mv-eno2 = {
  #   ipv4.addresses = [{ address = "192.168.1.61"; prefixLength = 24; }];
  # };
  users.mutableUsers = false;
  users.groups = { podman = { gid = 996; }; };
  users.users.jared = {
    isNormalUser = true;
    initialPassword = "helloworld";
    extraGroups = [ "podman" "wheel" ];
    openssh.authorizedKeys.keys = builtins.filter
      (str: builtins.stringLength str != 0)
      (lib.splitString "\n" (builtins.readFile ../../../lib/ssh_keys.txt));
  };
}
