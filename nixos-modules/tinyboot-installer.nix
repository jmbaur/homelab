{ config, lib, pkgs, ... }:
let
  espSizeMB = 128;

  espLabel = "ESP";

  espPartitionID = "22222222-2222-2222-2222-222222222222";

  squashfsLabel = "NIX_RO_STORE";

  squashfsImage = pkgs.callPackage "${pkgs.path}/nixos/lib/make-squashfs.nix" {
    storeContents = [ config.system.build.toplevel ];
  };

  populateBootPartition = ''
    mkdir -p $BOOT/loader/entries
    echo "type1" > $BOOT/loader/entries.srel
    echo "timeout ${toString config.boot.loader.timeout}" >> $BOOT/loader/loader.conf
    echo "default installer.conf" >> $BOOT/loader/loader.conf
    cp ${config.system.build.kernel}/${pkgs.stdenv.hostPlatform.linux-kernel.target} $BOOT/linux
    cp ${config.system.build.initialRamdisk}/initrd $BOOT/initrd
    cat > $BOOT/loader/entries/installer.conf <<EOF
    title NixOS Installer
    linux /linux
    initrd /initrd
    options init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}
    EOF
  '';
in
{
  options.custom.tinyboot-installer.enable = lib.mkEnableOption "tinyboot installer";

  config = lib.mkIf config.custom.tinyboot-installer.enable {
    assertions = [{ assertion = config.tinyboot.enable; message = "tinyboot not enabled"; }];

    custom.installer.enable = true;

    boot.initrd.systemd.enable = true;
    boot.initrd.systemd.emergencyAccess = true;

    boot.initrd.kernelModules = [ "squashfs" "loop" "overlay" ];

    boot.postBootCommands = ''
      # After booting, register the contents of the Nix store
      # in the Nix database in the tmpfs.
      ${config.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration

      # nixos-rebuild also requires a "system" profile and an
      # /etc/NIXOS tag.
      touch /etc/NIXOS
      ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
    '';

    fileSystems."/" = {
      fsType = "tmpfs";
      options = [ "size=2G" "mode=0755" "defaults" ];
    };
    fileSystems."/nix/.ro-store" = {
      fsType = "squashfs";
      device = "/dev/disk/by-partlabel/${squashfsLabel}";
      neededForBoot = true;
    };
    fileSystems."/nix/.rw-store" = {
      fsType = "tmpfs";
      options = [ "defaults" "mode=0755" ];
      neededForBoot = true;
    };
    fileSystems."/nix/store" = {
      fsType = "overlay";
      device = "overlay";
      options = [
        "lowerdir=/nix/.ro-store"
        "upperdir=/nix/.rw-store/store"
        "workdir=/nix/.rw-store/work"
      ];
      depends = [
        "/nix/.ro-store"
        "/nix/.rw-store/store"
        "/nix/.rw-store/work"
      ];
    };

    system.build = { inherit squashfsImage; };
    system.build.diskImage = pkgs.callPackage
      ({ stdenv
       , dosfstools
       , e2fsprogs
       , mtools
       , libfaketime
       , util-linux
       , zstd
       }: stdenv.mkDerivation (finalAttrs: {
        name = "tinyboot-installer";

        nativeBuildInputs = [ dosfstools e2fsprogs libfaketime mtools util-linux zstd ];

        buildCommand = ''
          mkdir -p $out/nix-support $out/disk-image
          export img=$out/disk-image/${finalAttrs.name}.raw

          echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
          echo "file disk-image $img.zst" >> $out/nix-support/hydra-build-products

          squashfs_image=${squashfsImage}

          # Create the image file sized to fit boot files and the squashfs image
          squashfsSizeBytes=$(du --bytes $squashfs_image | awk '{ print $1 }')
          extraBytes=$((8 * 1024 * 1024))
          imageSizeBytes=$((extraBytes + squashfsSizeBytes + ${toString (espSizeMB * 1024 * 1024)}))
          truncate -s $imageSizeBytes $img

          sfdisk $img <<EOF
              label: gpt
              label-id: 11111111-1111-1111-1111-111111111111

              size=${toString espSizeMB}M, type=uefi , uuid=${espPartitionID}                   , name=${espLabel}
              size=                      , type=linux, uuid=33333333-3333-3333-3333-333333333333, name=${squashfsLabel}
          EOF

          # Create a FAT32 filesystem for the boot partition of suitable size
          # into boot_part.img
          boot_image=$PWD/boot_part.img
          eval $(partx $img -o START,SECTORS --nr 1 --pairs)
          truncate -s $((SECTORS * 512)) $boot_image

          mkfs.vfat --invariant -i 0xdeadbeef -n ${espLabel} $boot_image

          # Populate the files intended for /boot
          export BOOT=$(mktemp -d)
          ${populateBootPartition}

          find $BOOT -exec touch --date=2000-01-01 {} +
          # Copy the populated /boot/firmware into the disk image
          pushd $BOOT
          # Force a fixed order in mcopy for better determinism, and avoid file globbing
          for d in $(find . -type d -mindepth 1 | sort); do
            faketime "2000-01-01 00:00:00" mmd -i $boot_image "::/$d"
          done
          for f in $(find . -type f | sort); do
            mcopy -pvm -i $boot_image "$f" "::/$f"
          done
          popd

          # Verify the FAT partition before copying it.
          fsck.vfat -vn $boot_image
          dd conv=notrunc if=$boot_image of=$img seek=$START count=$SECTORS

          # Copy the squashfs image into the disk image
          eval $(partx $img -o START,SECTORS --nr 2 --pairs)
          dd conv=notrunc if=$squashfs_image of=$img seek=$START count=$SECTORS

          zstd -T$NIX_BUILD_CORES --rm $img
        '';
      }))
      { };
  };
}
