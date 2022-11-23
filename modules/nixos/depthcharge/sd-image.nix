{ config, pkgs, ... }:
let
  rootfsImage = pkgs.callPackage "${pkgs.path}/nixos/lib/make-ext4-fs.nix" ({
    storePaths = [ config.system.build.toplevel ];
    compressImage = true;
    volumeLabel = "NIXOS_SD";
  });
in
{
  boot.loader.depthcharge = {
    enable = true;
    partition = "nodev";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
  system.build.sdImage = pkgs.callPackage
    ({ stdenv
     , dosfstools
     , dtc
     , e2fsprogs
     , libfaketime
     , mtools
     , parted
     , ubootTools
     , util-linux
     , vboot_reference
     , xz
     , zstd
     , ...
     }:
      stdenv.mkDerivation rec {
        name = "depthcharge-test-sd-image.img";
        nativeBuildInputs = [ dosfstools dtc e2fsprogs libfaketime mtools parted ubootTools util-linux vboot_reference xz zstd ];

        diskUUID = "EF23DEC7-DD70-4BE8-ACE3-98AA30EDCD96";
        bootUUID = "F789A61B-E9C2-4AE2-89BE-F234313B1CB4";
        rootUUID = "14B606EA-30A2-42BD-AF7D-95C184E96DCD";

        buildCommand = ''
          mkdir -p $out/nix-support $out/sd-image
          export img=$out/sd-image/${name}

          echo "${pkgs.stdenv.system}" > $out/nix-support/system
          echo "file sd-image $img.xz" >> $out/nix-support/hydra-build-products

          root_fs=./root-fs.img
          echo "Decompressing rootfs image"
          zstd -d --no-progress "${rootfsImage}" -o $root_fs

          # Create the image file sized to fit /, plus 20M of slack, plus a kernel partition
          kernelSizeMegs=64
          rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
          imageSize=$((rootSizeBlocks * 512 + (20 + $kernelSizeMegs) * 1024 * 1024))
          truncate -s $imageSize $img

          sfdisk --no-reread --no-tell-kernel $img <<EOF
              label: gpt
              label-id: $diskUUID
              size=64m, type=FE3A2A5D-4F32-41A7-B725-ACCC3285A309, uuid=$bootUUID, name=kernel
              type=B921B045-1DF0-41C3-AF44-4C6F280D3FAE, uuid=$rootUUID, name=NIXOS_SD
          EOF

          cgpt add -i 1 -S 1 -T 5 -P 10 $img

          # Copy the kernel to the SD image
          eval $(partx $img -o START,SECTORS --nr 1 --pairs)
          dd conv=notrunc if=${config.system.build.toplevel}/kpart of=$img seek=$START count=$SECTORS

          # Copy the rootfs into the SD image
          eval $(partx $img -o START,SECTORS --nr 2 --pairs)
          dd conv=notrunc if=$root_fs of=$img seek=$START count=$SECTORS

          zstd -T$NIX_BUILD_CORES --rm $img
        '';
      })
    { };
  boot.postBootCommands = ''
    # On the first boot do some maintenance tasks
    if [ -f /nix-path-registration ]; then
      # Figure out device names for the boot device and root filesystem.
      rootPart=$(readlink -f /dev/disk/by-label/NIXOS_SD)
      bootDevice=$(lsblk -npo PKNAME $rootPart)
      # Recreate the current partition table without the length limit
      sfdisk -d $bootDevice | ${pkgs.gnugrep}/bin/grep -v '^last-lba:' | sfdisk --no-reread $bootDevice
      # Resize the root partition and the filesystem to fit the disk
      echo ",+," | sfdisk -N2 --no-reread $bootDevice
      ${pkgs.parted}/bin/partprobe
      ${pkgs.e2fsprogs}/bin/resize2fs $rootPart
      # Register the contents of the initial Nix store
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration
      # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
      touch /etc/NIXOS
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      # Prevents this from running on later boots.
      rm -f /nix-path-registration
    fi
  '';
}
