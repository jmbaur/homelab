{ inputs, pkgs, lib, ... }: {
  imports = with inputs; [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  boot.kernelPackages = pkgs.linuxPackages_5_18;

  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

  users.users.nixos.openssh.authorizedKeys.keyFiles = [
    (import ./data/jmbaur-ssh-keys.nix)
  ];

  console.useXkbConfig = true;
  services.xserver.xkbOptions = "ctrl:nocaps";

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment = {
    variables.EDITOR = "vim";
    systemPackages = with pkgs; [ curl git tmux vim ];
  };
}
