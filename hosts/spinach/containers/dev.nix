{ config, lib, pkgs, ... }: {
  imports = [ ../../../lib/nix-unstable.nix ];
  networking.hostName = "dev";
  networking.interfaces.mv-eno2.useDHCP = true;

  environment.systemPackages = with pkgs; [ bind git htop neovim tmux wget ];
  services.openssh = { enable = false; ports = [ 2222 ]; };

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
