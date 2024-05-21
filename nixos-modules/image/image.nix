{
  coreutils,
  dosfstools,
  dtc,
  erofs-utils,
  fakeroot,
  formats,
  jq,
  lib,
  mtools,
  sbsigntool,
  squashfsTools,
  stdenv,
  systemd,
  systemdUkify,
  ubootTools,
  xz,

  # arguments
  bootFileCommands,
  id,
  imageName,
  partitions,
  postImageCommands,
  sectorSize,
  toplevelClosure,
  usrFormat,
  version,
}:

let
  iniFormat = formats.ini { };

  seed = "39c4020e-af73-434a-93e4-7e37fdcc7f96";

  bootPartition = partitions."10-boot" // { };

  dataPartition = partitions."20-usr-a" // {
    Minimize = true;
    Format = usrFormat;
    Verity = "data";
    VerityMatchKey = "usr";
    SplitName = "usr";
  };

  hashPartition = partitions."20-usr-hash-a" // {
    Minimize = true;
    Verity = "hash";
    VerityMatchKey = "usr";
    SplitName = "usr-hash";
  };

  systemdArchitecture = lib.replaceStrings [ "_" ] [ "-" ] stdenv.hostPlatform.linuxArch;

  bootPartitionConfig = iniFormat.generate "10-boot.conf" { Partition = bootPartition; };
  dataPartitionConfig = iniFormat.generate "20-usr-a.conf" { Partition = dataPartition; };
  hashPartitionConfig = iniFormat.generate "20-usr-hash-a.conf" { Partition = hashPartition; };
in
stdenv.mkDerivation {
  name = "nixos-image-${imageName}";

  depsBuildBuild =
    [
      dosfstools
      dtc
      fakeroot
      jq
      mtools
      sbsigntool
      systemd
      systemdUkify
      ubootTools
      xz
    ]
    ++ [
      {
        "erofs" = erofs-utils;
        "squashfs" = squashfsTools;
      }
      .${usrFormat}
    ];

  bootFileCommands =
    ''
      # source the setup file to get access to `substituteInPlace`
      source $stdenv/setup
    ''
    + bootFileCommands;
  passAsFile = [ "bootFileCommands" ];

  env = {
    SYSTEMD_REPART_MKFS_OPTIONS_EROFS = "-zlz4hc,12";
    SYSTEMD_REPART_MKFS_OPTIONS_SQUASHFS = "-comp zstd";
  };

  outputs = [
    "out"
    "update"
  ];

  buildCommand = ''
    install -Dm0644 ${bootPartitionConfig} repart.d/${bootPartitionConfig.name}
    install -Dm0644 ${dataPartitionConfig} repart.d/${dataPartitionConfig.name}
    install -Dm0644 ${hashPartitionConfig} repart.d/${hashPartitionConfig.name}

    echo "CopyFiles=${coreutils}/bin/env:/bin/env" >> repart.d/${dataPartitionConfig.name}
    echo "CopyFiles=${toplevelClosure}/registration:/.nix-path-registration" >> repart.d/${dataPartitionConfig.name}
    for path in $(cat ${toplevelClosure}/store-paths); do
      echo "CopyFiles=$path:''${path#/nix}" >> repart.d/${dataPartitionConfig.name}
    done

    repart_args=(
      "--dry-run=no"
      "--architecture=${systemdArchitecture}"
      "--seed=${seed}"
      "--sector-size=${toString sectorSize}"
      "--definitions=./repart.d"
      "--json=pretty"
    )

    mkdir -p $out $update

    fakeroot systemd-repart ''${repart_args[@]} \
      --defer-partitions=esp \
      --empty=create \
      --size=auto \
      --split=yes \
      $out/image.raw | tee repart-output.json

    export usrhash=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .roothash' <repart-output.json)

    export bootfiles=bootfiles
    bash "$bootFileCommandsPath"
    for line in $(cat $bootfiles); do
      echo "copying boot file $line"
      echo "CopyFiles=$line" >> repart.d/${bootPartitionConfig.name}
    done

    fakeroot systemd-repart ''${repart_args[@]} $out/image.raw

    data_uuid=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .uuid' <repart-output.json)
    hash_uuid=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}-verity") | .uuid' <repart-output.json)
    data_orig_path=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .split_path' <repart-output.json)
    hash_orig_path=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}-verity") | .split_path' <repart-output.json)
    data_new_path="''${update}/${id}_${version}_''${data_uuid}.usr.raw"
    hash_new_path="''${update}/${id}_${version}_''${hash_uuid}.usr-hash.raw"
    mv "$data_orig_path" "$data_new_path"
    mv "$hash_orig_path" "$hash_new_path"

    ${postImageCommands}

    xz -3 --compress --verbose --threads=0 $out/*.{raw,vhdx} $update/*.raw
  '';
}
