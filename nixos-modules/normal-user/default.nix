{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    findFirst
    getExe
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;

  cfg = config.custom.normalUser;

  usingBtrfs =
    config.fileSystems.${
      findFirst (path: config.fileSystems ? "${path}") (throw "mount not found") [
        "/home"
        "/"
      ]
    }.fsType == "btrfs";
in
{
  options.custom.normalUser = {
    enable = mkEnableOption "normal user";
    username = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        function fish_greeting
        end
      '';
    };

    users.mutableUsers = true;

    users.users.${cfg.username} = {
      isNormalUser = true;
      createHome = false; # we do this ourselves below
      shell = config.programs.fish.package;
      extraGroups =
        [ "wheel" ]
        ++ optional config.custom.dev.enable "dialout" # serial consoles
        ++ optional config.networking.networkmanager.enable "networkmanager"
        ++ optional config.programs.adb.enable "adbusers"
        ++ optional config.programs.wireshark.enable "wireshark"
        ++ optional config.services.yggdrasil.enable "yggdrasil"
        ++ optional config.virtualisation.docker.enable "docker";
    };

    systemd.tmpfiles.settings.home-directories.${config.users.users.${cfg.username}.home}.${
      if usingBtrfs then "v" else "d"
    } =
      {
        mode = config.users.users.${cfg.username}.homeMode;
        user = config.users.users.${cfg.username}.name;
        inherit (config.users.users.${cfg.username}) group;
      };

    systemd.services.configure-admin-user = {
      unitConfig.ConditionFirstBoot = true;

      wantedBy = [ "multi-user.target" ];

      after = [ "home.mount" ];
      before = [
        "systemd-user-sessions.service"
        "first-boot-complete.target"
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        StandardInput = "tty";
        StandardOutput = "tty";
        StandardError = "tty";

        ExecStart = getExe (
          pkgs.writeShellApplication {
            name = "configure-normal-user";

            runtimeInputs = [ pkgs.shadow ];

            text = ''
              trap "" INT # prevent CTRL-C

              stty sane

              printf "=%.0s" {1..80}
              printf "\n"

              if ! (
                while true; do
                  read -r -p "Please enter the real name for user ${cfg.username}: " real_name
                  if [[ -n "$real_name" ]]; then
                    break
                  fi
                done

                usermod --comment="$real_name" ${cfg.username}

                passwd "${cfg.username}"

                uid=$(id -u ${cfg.username})
                gid=$(id -g ${cfg.username})
                echo "''${uid}:$((0x80000)):$((0x10000))" >/etc/subuid
                echo "''${gid}:$((0x80000)):$((0x10000))" >/etc/subgid
              ); then
                echo "ERROR: failed to update normal user"
                sleep 20 # give the user some time to read any error output
              fi
            '';
          }
        );
      };
    };
  };
}
