{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.normalUser;

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
    assertions = [
      {
        assertion = config.systemd.sysusers.enable;
        message = "sysusers needs to be enabled";
      }
      {
        assertion = config.nix.enable -> config.nix.settings.auto-allocate-uids or false;
        message = "systemd-homed-firstboot does not work when auto-allocate-uids is not true because nixbld* users are considered 'regular' users";
      }
    ];

    systemd.additionalUpstreamSystemUnits = [ "systemd-homed-firstboot.service" ];

    systemd.services.systemd-homed-firstboot = {
      # TODO(jared): systemd-homed-firstboot won't run without this
      wantedBy = [ "first-boot-complete.target" ];

      serviceConfig = {
        ExecStart = [
          "" # clear upstream default
          (toString [
            "homectl"
            "firstboot"
            "--prompt-new-user"
            # above is default, custom stuff below
            "--enforce-password-policy=no"
            "--storage=${if fileSystemConfig.fsType == "btrfs" then "subvolume" else "directory"}"
          ])
        ];
        ExecStartPost = [
          # https://github.com/systemd/systemd/blob/477fdc5afed0457c43d01f3d7ace7209f81d3995/meson_options.txt#L246-L249
          (pkgs.writeShellScript "setup-subuid-and-subgid" ''
            eval $(homectl list --json=short | ${lib.getExe pkgs.jq} -r '"uid=\(.[0].uid)\ngid=\(.[0].gid)"')
            echo "$uid:$((0x80000)):$((0x10000))" >/etc/subuid
            echo "$gid:$((0x80000)):$((0x10000))" >/etc/subgid
          '')
        ];
      };
    };

    programs.fish = {
      enable = true;
      package = pkgs.fish;
      interactiveShellInit = ''
        function fish_greeting
        end
      '';
    };

    services.homed.enable = true;

    # This is needed if mutableUsers is false since we don't configure our
    # primary user through the traditional NixOS options. Since our primary
    # user is wheel, they can freely administer the machine, thus no need for a
    # root password or remote access (e.g. via ssh) to login as the root user.
    users.allowNoPasswordLogin = !config.users.mutableUsers;

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
