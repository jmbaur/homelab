{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    bind
    git
    htop
    neovim
    tmux
    wget
  ];
  virtualisation.podman = { enable = true; };
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
  };
  users.users.jared = {
    isNormalUser = true;
    initialPassword = "helloworld";
    openssh.authorizedKeys.keys = builtins.filter
      (str: builtins.stringLength str != 0)
      (lib.splitString "\n" (builtins.readFile ../../../lib/ssh_keys.txt));

  };
}
