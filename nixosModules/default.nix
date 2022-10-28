inputs: with inputs; {
  default = {
    nixpkgs.overlays = [ self.overlays.default ];
    imports = [
      ({ config, lib, ... }:
        let zfsDisabled = config.custom.disableZfs; in
        {
          options.custom.disableZfs = lib.mkEnableOption "disable zfs suppport";
          config = lib.mkIf zfsDisabled {
            boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
          };
        })
      ({ config, pkgs, lib, ... }:
        let
          cfg = config.custom.installer;
        in
        {
          options.custom.installer.enable = lib.mkEnableOption "installer";
          config = lib.mkIf cfg.enable {
            system.stateVersion = "22.11";
            boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
            custom.disableZfs = true;
            systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
            users.users.nixos.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
            console.useXkbConfig = true;
            services.xserver.xkbOptions = "ctrl:nocaps";
            nix = {
              package = pkgs.nixUnstable;
              extraOptions = ''
                experimental-features = nix-command flakes
              '';
            };
            environment = {
              variables.EDITOR = "nvim";
              systemPackages = with pkgs; [ curl git tmux neovim ];
            };
          };
        })
      ./cn913x.nix
      ./cross_compiled.nix
      ./deployee.nix
      ./deployer.nix
      ./jared.nix
      ./lx2k.nix
      ./remote_boot.nix
      ./remote_builder.nix
      ./thinkpad_x13s.nix
      ./wg_www_peer.nix
    ];
  };
}
