# TODO(jared): use systemd-homed
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.normalUser;

  # William Riker, first officer to Captain Picard, as this user is to root.
  username = "riker";

  groups =
    [ "wheel" ]
    ++ (lib.optional config.custom.dev.enable "dialout")
    ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
    ++ (lib.optional config.programs.adb.enable "adbusers")
    ++ (lib.optional config.programs.flashrom.enable "plugdev")
    ++ (lib.optional config.programs.wireshark.enable "wireshark")
    ++ (lib.optional config.virtualisation.docker.enable "docker");

  shell = if config.programs.fish.enable then pkgs.fish else pkgs.bash;

  mountpoint = lib.findFirst (path: config.fileSystems ? "${path}") (throw "mount not found") [
    "/home/${username}"
    "/home"
    "/"
  ];

  backingBlockDevice =
    config.fileSystems.${mountpoint}.device
      or "/dev/disk/by-label/${config.fileSystems.${mountpoint}.label}";
in
{
  options.custom.normalUser.enable = lib.mkEnableOption "normal user";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.users.mutableUsers;
        message = "mutableUsers required to change initial password";
      }
      {
        assertion = lib.any (fstype: fstype == config.fileSystems.${mountpoint}.fsType) [
          "ext4"
          "f2fs"
        ];
        message = "fscrypt requires ext4 or f2fs";
      }
    ];

    users.users.${username} = {
      isNormalUser = true;
      initialPassword = "NumberOne";
      inherit shell;
      extraGroups = groups;
    };

    security.pam.enableFscrypt = true;

    systemd.services.setup-home-encryption = {
      # TODO(jared): We should use ConditionFirstBoot, but this probably
      # won't work on NixOS.
      unitConfig.ConditionPathIsDirectory = [ "!/.fscrypt" ];
      # In nixpkgs, if sysusers is enabled, tmpfiles is used to create home
      # directories. See https://github.com/nixos/nixpkgs/blob/68165781ccbe4d2ff1d12b6e96ebe4a9f4a93d51/nixos/modules/system/boot/systemd/sysusers.nix#L100.
      after = lib.optionals config.systemd.sysusers.enable [ "systemd-tmpfiles-setup.service" ];
      path = [
        pkgs.e2fsprogs
        pkgs.fscrypt-experimental
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # setup filesystem to support fscrypt
        tune2fs -O encrypt $(readlink -f ${backingBlockDevice})

        # setup fscrypt
        fscrypt setup --quiet --force --time=1ms
        ${lib.optionalString (mountpoint != "/") ''
          fscrypt setup ${mountpoint} --quiet --force --time=1ms
        ''}

        # encrypt initial user's home directory
        echo ${
          config.users.users.${username}.initialPassword
        } | fscrypt encrypt --skip-unlock --source=pam_passphrase --no-recovery --user=${username} ${
          config.users.users.${username}.home
        }
      '';
      wantedBy = [ "multi-user.target" ];
    };
  };
}
