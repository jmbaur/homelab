{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.custom.normalUser;

  groups =
    [ "wheel" ]
    ++ (lib.optional config.custom.dev.enable "dialout")
    ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
    ++ (lib.optional config.programs.adb.enable "adbusers")
    ++ (lib.optional config.programs.flashrom.enable "plugdev")
    ++ (lib.optional config.programs.wireshark.enable "wireshark")
    ++ (lib.optional config.virtualisation.docker.enable "docker");

  mountpoint = lib.findFirst (path: config.fileSystems ? "${path}") (throw "mount not found") [
    "/home"
    "/"
  ];

  fileSystemConfig = config.fileSystems.${mountpoint};
in
{
  options.custom.normalUser = with lib; {
    enable = mkEnableOption "normal user";
  };

  config = lib.mkIf cfg.enable {
    services.homed.enable = true;

    # This is needed if mutableUsers is false since we don't configure our
    # primary user through the traditional NixOS options. Since our primary
    # user is wheel, they can freely administer the machine, thus no need for a
    # root password or remote access (e.g. via ssh) to login as the root user.
    users.allowNoPasswordLogin = !config.users.mutableUsers;

    # TODO(jared): We should use systemd-homed-firstboot.service when systemd
    # 256 is available. This depends on ConditionFirstBoot working in NixOS.
    # See https://github.com/NixOS/nixpkgs/pull/327552
    systemd.services.initial-user-setup = {
      unitConfig.ConditionPathExistsGlob = [ "!/home/*.homedir" ];
      wantedBy = [ config.systemd.services.systemd-homed.name ];
      after = [
        "home.mount"
        config.systemd.services.systemd-homed.name
      ];
      before = [
        config.systemd.services.systemd-user-sessions.name
        "first-boot-complete.target"
      ];
      path = [
        config.systemd.package
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ImportCredential = "home.*";
        StandardOutput = "tty";
        StandardInput = "tty";
        StandardError = "tty";
      };
      script = ''
        stty sane

        while true; do
          read -r -p "Please enter user name to create for admin user: " username
          if [[ -n "$username" ]]; then
            break
          fi
        done

        while true; do
          read -r -p "Real name for $username: " real_name
          if [[ -n "$real_name" ]]; then
            break
          fi
        done

        homectl create "$username" \
          --real-name="$real_name" \
          --member-of=${lib.concatStringsSep "," groups} \
          --shell=${utils.toShellPath config.users.defaultUserShell} \
          --storage=${if fileSystemConfig.fsType == "btrfs" then "subvolume" else "directory"} \
          --enforce-password-policy=no

        eval "$(homectl list --no-legend --json=short | jq -r --arg u "$username" '.[] | select(.name==$u) | "uid=\(.uid); export uid; gid=\(.gid); export gid;"')"

        # https://github.com/systemd/systemd/blob/477fdc5afed0457c43d01f3d7ace7209f81d3995/meson_options.txt#L246-L249
        echo "$uid:$((0x80000)):$((0x10000))" >/etc/subuid
        echo "$gid:$((0x80000)):$((0x10000))" >/etc/subgid
      '';
    };

    # Ugly: sshd refuses to start if a store path is given because /nix/store
    # is group-writable. So indirect by a symlink.
    environment.etc."ssh/homed_authorized_keys_command" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        exec ${lib.getExe' config.systemd.package "userdbctl"} ssh-authorized-keys "$@"
      '';
    };

    # TODO(jared): nixos doesn't have nice options for specifying match blocks
    #
    # https://wiki.archlinux.org/title/systemd-homed#SSH_remote_unlocking
    services.openssh.extraConfig = ''
      Match User *,!root
        PasswordAuthentication yes
        PubkeyAuthentication yes
        AuthenticationMethods publickey,password
        AuthorizedKeysCommand /etc/ssh/homed_authorized_keys_command %u
        AuthorizedKeysCommandUser root
    '';
  };
}
