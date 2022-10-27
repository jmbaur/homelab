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
      ./lx2k.nix
      ./cn913x.nix
      ./thinkpad_x13s.nix
      ./remote_boot.nix
      ./deployee.nix
      ./deployer.nix
      ./jared.nix
      ({ config, lib, pkgs, ... }: {
        options.custom.remoteBuilders = {
          aarch64builder.enable = lib.mkEnableOption "aarch64 builder";
        };
        config = {
          nix.buildMachines =
            (lib.optional config.custom.remoteBuilders.aarch64builder.enable {
              hostName = "aarch64builder";
              system = "aarch64-linux";
              maxJobs = 8;
              speedFactor = 2;
              supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
              mandatoryFeatures = [ ];
            });
          nix.distributedBuilds = true;
          # optional, useful when the builder has a faster internet connection than yours
          nix.extraOptions = ''
            builders-use-substitutes = true
          '';

          programs.ssh = {
            knownHostsFiles = [
              (pkgs.writeText "known_hosts" ''
                kale.mgmt.home.arpa ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6q44hTsu6FVYG5izJxymw33SZJRDMttHxrwNBqdSJl
              '')
            ];
            extraConfig = ''
              Host aarch64builder
                User root
                HostName kale.mgmt.home.arpa
                IdentitiesOnly yes
                IdentityFile /root/.ssh/id_ed25519
            '';
          };
        };
      })
      ./wg_www_peer.nix
      ./cross_compiled.nix
    ];
  };
}
