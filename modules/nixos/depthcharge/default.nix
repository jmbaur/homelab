{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.boot.loader.depthcharge;

  makeKernelITS = pkgs.runCommand "make-kernel-its.bash" { } ''
    cp ${./make-kernel-its.bash} $out
    chmod a+x $out
    patchShebangs $out
  '';
  makeKpart = pkgs.runCommand "make-kpart.bash"
    {
      inherit (pkgs) vboot_reference ubootTools dtc xz;
      inherit makeKernelITS;
    } ''
    substituteAll ${./make-kpart.bash} $out
    chmod a+x $out
    patchShebangs $out
  '';

  fallbackDeviceSetup = optionalString (cfg.fallbackPartition != null) ''
    export PATH=${lib.makeBinPath [ pkgs.vboot_reference pkgs.util-linux ]}:$PATH
    deviceToDisk() {
      local device=$1
      local name
      name=$(lsblk -no pkname "$device")
      echo "/dev/$name"
    }
    deviceToIndex() {
      local disk=$1
      local device=$2
      local PARTUUID
      source <(blkid --output export "$device" | grep '^PARTUUID=' | tr 'a-f' 'A-F')
      cgpt find -n -u "$PARTUUID" "$disk"
    }
    primary_disk=$(deviceToDisk ${cfg.partition})
    primary_index=$(deviceToIndex "$primary_disk" ${cfg.partition})
    fallback_disk=$(deviceToDisk ${cfg.fallbackPartition})
    fallback_index=$(deviceToIndex "$fallback_disk" ${cfg.fallbackPartition})
    if [ "$primary_disk" != "$fallback_disk" ]; then
      echo "Primary partition and fallback partition are not on the same disk" >&2
      exit 1
    fi
  '';
in

{
  options.boot.loader.depthcharge = {
    enable = mkEnableOption "depthcharge bootloader support";
    partition = mkOption {
      example = "/dev/disk/by-partlabel/kernel";
      type = types.str;
      description = ''
        The kernel partition that holds the boot configuration. The
        value "nodev" indiciates the kpart partition should be
        created but not installed.
      '';
    };
    fallbackPartition = mkOption {
      example = "/dev/disk/by-partlabel/kernel-fallback";
      type = types.nullOr types.str;
      default = null;
      description = ''
        If not null, this partition will be used to boot a known
        good system if the primary partition fails to boot.
      '';
    };
  };

  config = mkIf config.boot.loader.depthcharge.enable {
    environment.systemPackages = [ pkgs.vboot_reference ];
    console.earlySetup = true;
    boot.loader.grub.enable = false;
    system.boot.loader.id = "depthcharge";
    system.extraSystemBuilderCmds = ''
      ${makeKpart} $out
    '';

    system.build.installBootLoader =
      let
        program = pkgs.writeShellApplication {
          name = "install-depthcharge";
          runtimeInputs = [ pkgs.vboot_reference ];
          text = ''
            system=$1
            kpart=$system/kpart
            if [ ! -f "$kpart" ]; then
              echo "Missing kpart file in system"
              echo "Expected: $kpart"
              exit 1
            fi
            ${if cfg.partition != "nodev" then ''
              summary() {
                file=$1
                futility show --strict "$file" | grep -v "Kernel partition"
              }
              if ! diff --brief <(summary ${cfg.partition}) <(summary "$system/kpart"); then
              ${fallbackDeviceSetup}
              ${lib.optionalString (cfg.fallbackPartition != null) ''
                if [ -e /run/booted-system/kpart ]; then
                  echo "Copying booted kernel to fallback partition"
                  dd if=/run/booted-system/kpart of="${cfg.fallbackPartition}"
                  echo "Setting known good configuration as known good"
                  cgpt add -i "$fallback_index" -T 0 -S 1 "$fallback_disk"
                fi
              ''}
                echo "Installing kpart at $kpart to ${cfg.partition}"
                dd if="$kpart" of="${cfg.partition}"
              ${lib.optionalString (cfg.fallbackPartition != null) ''
                echo "Setting new kpart state"
                cgpt add -i "$primary_index" -T 1 -S 0 "$primary_disk"
                cgpt prioritize -i "$primary_index" "$primary_disk"
              ''}
              fi
            '' else ''
              echo "Kpart produced at $kpart, but automatic installation is disabled."
            ''}
          '';
        };
      in
      "${program}/bin/install-depthcharge";

    systemd.services.set-successful-boot = mkIf (cfg.fallbackPartition != null) {
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      script = ''
        set -euo pipefail
        ${fallbackDeviceSetup}
        good_kpart=$(readlink -f /run/booted-system/kpart)
        # use the /run/booted-system kpart
        kpart_length=$(stat -c '%s' "$good_kpart")
        set_active_if_match() {
          local partition=$1
          local disk=$2
          local index=$3
          if cmp -n "$kpart_length" "$good_kpart" "$partition"; then
            echo "Booted system found at $partition, setting successful flag on $disk:$index"
            cgpt add -i "$index" -S 1 "$disk"
            cgpt prioritize -i "$index" "$disk"
          else
            echo "$partition doesn't match"
          fi
        }
        set_active_if_match "${cfg.partition}" "$primary_disk" "$primary_index"
      '';
      path = with pkgs; [ diffutils vboot_reference ];
    };
  };
}
