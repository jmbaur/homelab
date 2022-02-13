{ config, lib, pkgs, ... }: {
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  users.users.root.openssh.authorizedKeys.keys =
    (import ../data/asparagus-ssh-keys.nix)
    ++
    (import ../data/beetroot-ssh-keys.nix);
}
