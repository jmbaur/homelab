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
              variables.EDITOR = "vim";
              systemPackages = with pkgs; [ curl git tmux vim ];
            };
          };
        })
      ({ config, pkgs, lib, ... }:
        let cfg = config.hardware.lx2k; in
        {
          options.hardware.lx2k.enable = lib.mkEnableOption "hardware support for the Honeycomb LX2K board";
          config = lib.mkIf cfg.enable {
            boot.kernelParams = [
              "console=ttyAMA0,115200"
              "arm-smmu.disable_bypass=0"
              "iommu.passthrough=1"
              "amdgpu.pcie_gen_cap=0x4"
              "usbcore.autosuspend=-1"
            ];
            boot.kernelPackages = pkgs.linuxPackages_5_19;

            # Setup SFP+ network interfaces early so systemd can pick everything up.
            boot.initrd.extraUtilsCommands = ''
              copy_bin_and_libs ${pkgs.restool}/bin/restool
              copy_bin_and_libs ${pkgs.restool}/bin/ls-main
              copy_bin_and_libs ${pkgs.restool}/bin/ls-addni
                # Patch paths
                sed -i "1i #!$out/bin/sh" $out/bin/ls-main
            '';
            boot.initrd.postDeviceCommands = ''
              ls-addni dpmac.7
              ls-addni dpmac.8
              ls-addni dpmac.9
              ls-addni dpmac.10
            '';
          };
        })
      ({ config, lib, pkgs, ... }:
        let
          cfg = config.hardware.cn913x;
          kernelPatches = [
            {
              name = "0001-arm64-dts-cn913x-add-cn913x-based-COM-express-type-";
              patch = "${cn913x_build}/patches/linux/0001-arm64-dts-cn913x-add-cn913x-based-COM-express-type-.patch";
            }
            {
              name = "0002-arm64-dts-cn913x-add-cn913x-COM-device-trees-to-the";
              patch = "${cn913x_build}/patches/linux/0002-arm64-dts-cn913x-add-cn913x-COM-device-trees-to-the.patch";
            }
            {
              name = "0004-dts-update-device-trees-to-cn913x-rev-1";
              patch = "${cn913x_build}/patches/linux/0004-dts-update-device-trees-to-cn913x-rev-1.1.patch";
            }
            {
              name = "0005-DTS-update-cn9130-device-tree";
              patch = "${cn913x_build}/patches/linux/0005-DTS-update-cn9130-device-tree.patch";
            }
            {
              name = "0007-update-spi-clock-frequency-to-10MHz";
              patch = "${cn913x_build}/patches/linux/0007-update-spi-clock-frequency-to-10MHz.patch";
            }
            {
              name = "0009-dts-cn9130-som-for-clearfog-base-and-pro";
              patch = "${cn913x_build}/patches/linux/0009-dts-cn9130-som-for-clearfog-base-and-pro.patch";
            }
            {
              name = "0010-dts-add-usb2-support-and-interrupt-btn";
              patch = "${cn913x_build}/patches/linux/0010-dts-add-usb2-support-and-interrupt-btn.patch";
            }
            {
              name = "0011-linux-add-support-cn9131-cf-solidwan";
              patch = "${cn913x_build}/patches/linux/0011-linux-add-support-cn9131-cf-solidwan.patch";
            }
            {
              name = "0012-linux-add-support-cn9131-bldn-mbv";
              patch = "${cn913x_build}/patches/linux/0012-linux-add-support-cn9131-bldn-mbv.patch";
            }
            {
              name = "0013-cpufreq-armada-enable-ap807-cpu-clk";
              patch = "${cn913x_build}/patches/linux/0013-cpufreq-armada-enable-ap807-cpu-clk.patch";
            }
            {
              name = "cn913x_additions";
              patch = null;
              extraConfig =
                let
                  cn913x_additions = pkgs.runCommand "cn913x_additions_fixup" { } ''
                    ${pkgs.gnused}/bin/sed 's/CONFIG_\(.*\)=\(.*\)/\1 \2/' ${cn913x_build}/configs/linux/cn913x_additions.config > $out
                  '';
                in
                builtins.readFile "${cn913x_additions}";
            }
          ];
        in
        {
          options.hardware.cn913x.enable = lib.mkEnableOption "cn913x hardware";
          config = lib.mkIf cfg.enable {
            boot = {
              initrd.systemd.enable = true;
              kernelPackages = pkgs.linuxPackages_5_15;
              kernelPatches = kernelPatches;
            };
            hardware.deviceTree = {
              enable = true;
              filter = "cn913*.dtb";
            };
          };
        })
      ({ config, lib, pkgs, ... }:
        let cfg = config.hardware.thinkpad-x13s; in
        with lib; {
          options.hardware.thinkpad-x13s.enable = mkEnableOption "hardware support for ThinkPad X13s";
          config = mkIf cfg.enable {
            custom.disableZfs = true;
            boot = {
              kernelPackages = pkgs.linuxPackages_testing;
              kernelParams = [
                "dtb=/boot/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb"
                "video=efifb:auto"
                "audit=0"
                "efi=novamap,noruntime"
                "pd_ignore_unused"
                "clk_ignore_unused"
              ];
              loader.grub = {
                efiSupport = true;
                extraFiles."dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb" = "${config.boot.kernelPackages.kernel}/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
              };
            };
            hardware.deviceTree = {
              enable = true;
              name = "sc8280xp-lenovo-thinkpad-x13s.dtb";
            };
          };
        })
      ({ config, lib, ... }:
        let
          cfg = config.custom.remoteBoot;
        in
        with lib;
        {
          options.custom.remoteBoot = {
            enable = mkOption {
              type = types.bool;
              default = (config.custom.deployee.enable) && (config.boot.initrd.luks.devices != { });
              description = ''
                Enable remote boot
              '';
            };
            interface = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The interface to use for autoconfiguration during stage-1 boot
              '';
            };
            authorizedKeyFiles = mkOption {
              type = types.listOf types.path;
              default = [ ];
            };
          };
          config = mkIf cfg.enable {
            assertions = [{
              assertion = config.services.openssh.enable;
              message = "OpenSSH must be enabled on host";
            }];
            boot = {
              kernelParams = [
                (if cfg.interface == null then
                  "ip=dhcp"
                else
                  "ip=:::::${cfg.interface}:dhcp")
              ];
              initrd.network = {
                enable = true;
                postCommands = ''
                  echo "cryptsetup-askpass; exit" > /root/.profile
                '';
                ssh = {
                  enable = true;
                  hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ];
                  authorizedKeys = lib.flatten (map
                    (file:
                      (builtins.filter
                        (content: content != "")
                        (lib.splitString "\n" (builtins.readFile file))
                      ))
                    cfg.authorizedKeyFiles);
                };
              };
            };
          };
        })
      ({ config, lib, ... }:
        let
          cfg = config.custom.deployee;
        in
        with lib;
        {
          options.custom.deployee = {
            enable = mkEnableOption "deploy target";
            authorizedKeys = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };
            authorizedKeyFiles = mkOption {
              type = types.listOf types.path;
              default = [ ];
            };
          };

          config = mkIf cfg.enable {
            assertions = [{
              assertion = (cfg.authorizedKeyFiles != [ ] || cfg.authorizedKeys != [ ]);
              message = "No authorized keys configured for deployee";
            }];

            services.openssh = {
              enable = true;
              listenAddresses = [ ]; # this defaults to all addresses
            };

            users.users.root.openssh.authorizedKeys = {
              keys = cfg.authorizedKeys;
              keyFiles = cfg.authorizedKeyFiles;
            };
          };
        })
      ({ config, lib, pkgs, ... }:
        let
          cfg = config.custom.deployer;
        in
        with lib;
        {
          options.custom.deployer = {
            enable = mkEnableOption "this machine to deploy to other machines";
            authorizedKeyFiles = mkOption {
              type = types.listOf types.path;
              default = [ ];
            };
          };
          config = mkIf cfg.enable {
            # Must be able to bootstrap the deployer, allow SSH access to the
            # deployer by personal keys.
            assertions = [{
              assertion = (cfg.authorizedKeyFiles != [ ]);
              message = "No authorized keys configured for deployer";
            }];
            users.users.deploy = {
              uid = 2000;
              isNormalUser = true;
              description = "Deployer";
              packages = [ pkgs.deploy-rs ];
              openssh.authorizedKeys.keyFiles = cfg.authorizedKeyFiles;
            };
            system.activationScripts.deployer.text = ''
              # Make sure we don't write to stdout, since in case of
              # socket activation, it goes to the remote side (#19589).
              exec >&2

              path="${config.users.users.deploy.home}/.ssh"
              mkdir -m 0755 -p "$path"

              keyfile="''${path}/id_ed25519"
              if ! [ -s "$keyfile" ]; then
                rm -f "$keyfile"
                ${pkgs.openssh}/bin/ssh-keygen \
                  -C "${config.users.users.deploy.name}@${config.networking.hostName}" \
                  -t "ed25519" \
                  -f "$keyfile" \
                  -N ""
              fi

              chown -R ${toString config.users.users.deploy.uid}:${config.users.users.deploy.group} "$path"
            '';
          };
        })
      ({ secrets, lib, config, pkgs, ... }:
        let cfg = config.custom.users.jared; in
        {
          options.custom.users.jared.enable = lib.mkEnableOption "jared";
          config = lib.mkIf cfg.enable {
            programs.fish.enable = true;
            users.users.jared = {
              isNormalUser = true;
              description = "Jared Baur";
              extraGroups = [ "dialout" "wheel" ];
              shell = pkgs.fish;
              openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
              inherit (secrets.users.jared) hashedPassword;
            };
          };
        })
      ({ config, lib, pkgs, ... }: {
        options.custom.remoteBuilders = {
          aarch64builder.enable = lib.mkEnableOption "aarch64 builder";
        };
        config = {
          nix.buildMachines =
            (lib.optional config.custom.remoteBuilders.aarch64builder.enable {
              hostName = "aarch64builder";
              system = "aarch64-linux";
              # if the builder supports building for multiple architectures,
              # replace the previous line by, e.g.,
              # systems = ["x86_64-linux" "aarch64-linux"];
              maxJobs = 1;
              speedFactor = 2;
              supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
              mandatoryFeatures = [ ];
            })
            # ++
            # ()
          ;

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
      ({ config, lib, inventory, ... }:
        let
          cfg = config.custom.wgWwwPeer;
        in
        {
          options.custom.wgWwwPeer.enable = lib.mkEnableOption "wireguard peer to www";
          config = lib.mkIf cfg.enable {
            assertions = [{
              assertion = config.networking.useNetworkd;
              message = "systemd-networkd not used";
            }];
            systemd.network = let wgPublic = inventory.networks.wg-public; in
              {
                netdevs.wg-public = {
                  netdevConfig = {
                    Name = "wg-public";
                    Kind = "wireguard";
                  };
                  wireguardPeers = [{
                    wireguardPeerConfig = {
                      PublicKey = wgPublic.hosts.www.publicKey;
                      Endpoint = "www.jmbaur.com:${toString (51800 + wgPublic.id)}";
                      PersistentKeepalive = 25;
                      AllowedIPs = with wgPublic.hosts.www; [
                        "${ipv4}/32"
                        "${ipv6.ula}/128"
                        "${ipv6.gua}/128"
                      ];
                    };
                  }];
                  wireguardConfig.PrivateKeyFile = config.age.secrets."wg-public-${config.networking.hostName}".path;
                };
                networks.wg-public = {
                  name = "wg-public";
                  address = with wgPublic.hosts.${config.networking.hostName}; [
                    "${ipv4}/${toString wgPublic.ipv4Cidr}"
                    "${ipv6.ula}/${toString wgPublic.ipv6Cidr}"
                  ];
                };
              };
          };
        })
    ];
  };
}
