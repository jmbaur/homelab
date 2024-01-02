{ closureInfo
, dosfstools
, dtc
, fakeroot
, formats
, jq
, mtools
, sbsigntool
, squashfsTools
, stdenv
, systemd
, ubootTools
, xz
, zstd

  # arguments
, toplevel
, bootFileCommands
, partitions
, usrFormat
, imageName
}:

let
  seed = "39c4020e-af73-434a-93e4-7e37fdcc7f96";

  bootPartition = partitions."10-boot" // { };

  # We want to enforce SizeMaxBytes when creating the data and hash partitions
  # during image creation, since we would rather the image fail to build then
  # the initrd repart process to result in the "A" and "B" partitions having
  # different sizes. We remove SizeMinBytes since we want the image to be as
  # small as possible.
  dataPartition = builtins.removeAttrs
    (partitions."20-usr-a" // {
      Minimize = "best";
      Format = usrFormat;
      Verity = "data";
      VerityMatchKey = "usr";
      SplitName = "usr";
    }) [ "SizeMinBytes" ];

  hashPartition = partitions."20-usr-a-hash" // {
    Verity = "hash";
    VerityMatchKey = "usr";
    SplitName = "usr-hash";
  };

  systemdArchitecture = builtins.replaceStrings [ "_" ] [ "-" ] stdenv.hostPlatform.linuxArch;
  closure = closureInfo { rootPaths = [ toplevel ]; };

  bootPartitionConfig = (formats.ini { }).generate "10-boot.conf" { Partition = bootPartition; };
  dataPartitionConfig = (formats.ini { }).generate "20-usr-a.conf" { Partition = dataPartition; };
  hashPartitionConfig = (formats.ini { }).generate "20-usr-a-hash.conf" { Partition = hashPartition; };
in
stdenv.mkDerivation {
  name = "nixos-image-${imageName}";

  depsBuildBuild = [
    dosfstools
    dtc
    fakeroot
    jq
    mtools
    sbsigntool
    squashfsTools
    systemd
    ubootTools
    xz
    zstd
  ];

  inherit bootFileCommands;
  passAsFile = [ "bootFileCommands" ];

  buildCommand = ''
    install -Dm0644 ${bootPartitionConfig} repart.d/10-boot.conf
    install -Dm0644 ${dataPartitionConfig} repart.d/20-usr-a.conf
    install -Dm0644 ${hashPartitionConfig} repart.d/20-usr-a-hash.conf

    echo "CopyFiles=${closure}/registration:/.nix-path-registration" >> repart.d/20-usr-a.conf
    for path in $(cat ${closure}/store-paths); do
      echo "CopyFiles=$path:''${path#/nix/store}" >> repart.d/20-usr-a.conf
    done

    repart_args=(
      "--dry-run=no"
      "--architecture=${systemdArchitecture}"
      "--seed=${seed}"
      "--definitions=./repart.d"
      "--json=pretty"
    )

    mkdir -p $out

    fakeroot systemd-repart ''${repart_args[@]} \
      --defer-partitions=esp \
      --empty=create \
      --size=auto \
      --split=yes \
      $out/image.raw \
      | tee $out/repart-output.json

    export bootfiles=bootfiles
    bash "$bootFileCommandsPath"
    for line in $(cat $bootfiles); do
      echo "copying boot file $line"
      echo "CopyFiles=$line" >> repart.d/10-boot.conf
    done

    fakeroot systemd-repart ''${repart_args[@]} \
      $out/image.raw

    zstd --rm $out/*.raw
  '';
}
