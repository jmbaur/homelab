{
  config,
  lib,
  pkgs,
  utils,
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

  shell =
    if config.programs.fish.enable then
      pkgs.fish
    else if config.programs.zsh.enable then
      pkgs.zsh
    else
      pkgs.bash;

  mountpoint = lib.findFirst (path: config.fileSystems ? "${path}") (throw "mount not found") [
    "/home/${username}"
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

    systemd.services.initial-user-setup = {
      # TODO(jared): We should use ConditionFirstBoot, but this probably
      # won't work on NixOS.
      unitConfig.ConditionPathIsDirectory = [ "!/home/${username}.homedir" ];
      # In nixpkgs, if sysusers is enabled, tmpfiles is used to create home
      # directories. See https://github.com/nixos/nixpkgs/blob/68165781ccbe4d2ff1d12b6e96ebe4a9f4a93d51/nixos/modules/system/boot/systemd/sysusers.nix#L100.
      after = [ "systemd-homed.service" ];
      path = [
        config.systemd.package
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        env NEWPASSWORD=NumberOne homectl create ${username} \
          --member-of=${lib.concatStringsSep "," groups} \
          --shell=${utils.toShellPath shell} \
          --storage=${if fileSystemConfig.fsType == "btrfs" then "subvolume" else "directory"} \
          --enforce-password-policy=no

        eval "$(homectl --json=short | jq -r '.[] | select(.name=="${username}") | "uid=\(.uid); export uid; gid=\(.gid); export gid;"')"

        # https://github.com/systemd/systemd/blob/477fdc5afed0457c43d01f3d7ace7209f81d3995/meson_options.txt#L246-L249
        echo "$uid:$((0x80000)):$((0x10000))" >/etc/subuid
        echo "$gid:$((0x80000)):$((0x10000))" >/etc/subgid
      '';
      wantedBy = [ "multi-user.target" ];
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