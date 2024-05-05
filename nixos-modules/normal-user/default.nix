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
      path = [ config.systemd.package ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        env NEWPASSWORD=NumberOne homectl create ${username} \
          --member-of=${lib.concatStringsSep "," groups} \
          --shell=${utils.toShellPath shell} \
          --password-hint="Picard's nickname for Riker" \
          --storage=${if fileSystemConfig.fsType == "btrfs" then "subvolume" else "directory"} \
          --enforce-password-policy=no
      '';
      wantedBy = [ "multi-user.target" ];
    };

    # TODO(jared): nixos doesn't have nice options for specifying match blocks
    #
    # https://wiki.archlinux.org/title/systemd-homed#SSH_remote_unlocking
    services.openssh.extraConfig = ''
      Match Group wheel
        PasswordAuthentication yes
        PubkeyAuthentication yes
        AuthenticationMethods publickey,password
        AuthorizedKeysCommand ${lib.getExe' config.systemd.package "userdbctl"} ssh-authorized-keys %u
        AuthorizedKeysCommandUser root
    '';
  };
}
