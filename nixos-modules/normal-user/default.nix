{ config, lib, ... }:

let
  inherit (lib)
    getExe'
    mkEnableOption
    mkIf
    ;

  cfg = config.custom.normalUser;
in
{
  options.custom.normalUser = {
    enable = mkEnableOption "normal user";
  };

  config = mkIf cfg.enable {
    # This is needed if mutableUsers is false since we don't configure our
    # primary user through the traditional NixOS options. Since our primary
    # user is wheel, they can freely administer the machine, thus no need for a
    # root password or remote access (e.g. via ssh) to login as the root user.
    users.allowNoPasswordLogin = !config.users.mutableUsers;

    # TODO(jared): Use upstream unit as-is
    systemd.services.systemd-homed-firstboot.serviceConfig.ExecStart = [
      "" # clear upstream default
      (toString [
        "homectl"
        "firstboot"
        "--prompt-new-user"
        # above is default, custom stuff below
        "--enforce-password-policy=no"
      ])
    ];

    services.homed.enable = true;

    # Ugly: sshd refuses to start if a store path is given because /nix/store
    # is group-writable. So indirect by a symlink.
    environment.etc."ssh/homed_authorized_keys_command" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        exec ${getExe' config.systemd.package "userdbctl"} ssh-authorized-keys "$@"
      '';
    };

    # TODO(jared): nixos doesn't have nice options for specifying match blocks
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
