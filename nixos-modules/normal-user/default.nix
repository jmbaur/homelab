{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    getExe
    getExe'
    mkEnableOption
    mkIf
    optional
    ;

  cfg = config.custom.normalUser;

  groups =
    [ "wheel" ]
    ++ optional config.custom.dev.enable "dialout" # serial consoles
    ++ optional config.networking.networkmanager.enable "networkmanager"
    ++ optional config.programs.adb.enable "adbusers"
    ++ optional config.programs.wireshark.enable "wireshark"
    ++ optional config.virtualisation.docker.enable "docker";

in
{
  options.custom.normalUser.enable = mkEnableOption "normal user";

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        function fish_greeting
        end
      '';
    };

    users.mutableUsers = true;

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
            name = "configure-admin-user";

            runtimeInputs = [
              pkgs.util-linux # findmnt
              # TODO(jared): should go upstream
              (pkgs.shadow.overrideAttrs (old: {
                postPatch =
                  (old.postPatch or "")
                  + ''
                    substituteInPlace lib/btrfs.c \
                      --replace-fail /usr/bin/btrfs ${getExe' pkgs.btrfs-progs "btrfs"}
                  '';
              }))
            ];

            text = ''
              trap "" INT # prevent CTRL-C

              stty sane

              printf "=%.0s" {1..80}
              printf "\n"

              if ! (
                while true; do
                  read -r -p "Please enter a username: " username
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

                while true; do
                  read -s -r -p "Password for user $username: " password
                  if [[ -n "$password" ]]; then
                    break
                  fi
                done

                touch /etc/sub{u,g}id

                gid=${toString config.users.groups.users.gid}

                declare -a useradd_args=("--create-home")

                if [[ $(findmnt --noheadings --output=FSTYPE --target=/home --direction=backward) == "btrfs" ]]; then
                  useradd_args+=("--btrfs-subvolume-home")
                fi

                useradd_args+=("--comment=$real_name" "--gid=$gid" "--groups=${concatStringsSep "," groups}")
                useradd_args+=("$username")

                umask 077 # set the umask prior to home directory creation so $HOME has the right mode
                useradd "''${useradd_args[@]}"

                uid=$(id -u "$username")
                echo "$uid:$((0x80000)):$((0x10000))" >/etc/subuid
                echo "$gid:$((0x80000)):$((0x10000))" >/etc/subgid

                echo "''${username}:''${password}" | chpasswd
              ); then
                echo "ERROR: failed to create admin user"
                sleep 20 # give the user some time to read any error output
              fi
            '';
          }
        );
      };
    };
  };
}
