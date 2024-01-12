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

  # arguments
, bootFileCommands
, distroId
, imageName
, partitions
, postImageCommands
, toplevel
, usrFormat
, version
}:

let
  iniFormat = formats.ini { };

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

  hashPartition = partitions."20-usr-hash-a" // {
    Verity = "hash";
    VerityMatchKey = "usr";
    SplitName = "usr-hash";
  };

  systemdArchitecture = builtins.replaceStrings [ "_" ] [ "-" ] stdenv.hostPlatform.linuxArch;
  closure = closureInfo { rootPaths = [ toplevel ]; };

  bootPartitionConfig = iniFormat.generate "10-boot.conf" { Partition = bootPartition; };
  dataPartitionConfig = iniFormat.generate "20-usr-a.conf" { Partition = dataPartition; };
  hashPartitionConfig = iniFormat.generate "20-usr-hash-a.conf" { Partition = hashPartition; };
in
stdenv.mkDerivation {
  name = "nixos-image-${imageName}";

  depsBuildBuild = [ dosfstools dtc fakeroot jq mtools sbsigntool squashfsTools systemd ubootTools xz ];

  outputs = [ "out" "update" ];

  inherit bootFileCommands;
  passAsFile = [ "bootFileCommands" ];

  buildCommand = ''
    install -Dm0644 ${bootPartitionConfig} repart.d/10-boot.conf
    install -Dm0644 ${dataPartitionConfig} repart.d/20-usr-a.conf
    install -Dm0644 ${hashPartitionConfig} repart.d/20-usr-hash-a.conf

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

    mkdir -p $out $update

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

    ${postImageCommands}

    data_uuid=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .uuid' <$out/repart-output.json)
    hash_uuid=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}-verity") | .uuid' <$out/repart-output.json)
    data_orig_path=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .split_path' <$out/repart-output.json)
    hash_orig_path=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}-verity") | .split_path' <$out/repart-output.json)

    data_new_path="''${update}/${distroId}_${toString version}_''${data_uuid}_1_1.usr.raw"
    hash_new_path="''${update}/${distroId}_${toString version}_''${hash_uuid}_1_1.usr-hash.raw"

    mv "$data_orig_path" "$data_new_path"
    mv "$hash_orig_path" "$hash_new_path"

    xz -3 --compress --verbose --threads=0 $out/*.{raw,vhdx} $update/*.raw
  '';
}
