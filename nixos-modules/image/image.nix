{
  coreutils-full,
  dosfstools,
  dtc,
  erofs-utils,
  fakeroot,
  formats,
  jq,
  lib,
  mtools,
  nix,
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
  maxUsrPadding,
  maxUsrHashPadding,
}:

let
  iniFormat = formats.ini { };

  seed = "39c4020e-af73-434a-93e4-7e37fdcc7f96";

  bootPartition = partitions."10-boot" // { };

  dataPartition = partitions."20-usr-a" // {
    PaddingMinBytes = toString maxUsrPadding;
    PaddingMaxBytes = toString maxUsrPadding;
    Minimize = true;
    Format = usrFormat;
    Verity = "data";
    VerityMatchKey = "usr";
    SplitName = "usr";
  };

  hashPartition = partitions."20-usr-hash-a" // {
    PaddingMinBytes = toString maxUsrHashPadding;
    PaddingMaxBytes = toString maxUsrHashPadding;
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
      nix
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

  outputs = [
    "out"
    "update"
  ];

  buildCommand = ''
    export SYSTEMD_REPART_MKFS_OPTIONS_EROFS="-zlz4hc,12"
    export SYSTEMD_REPART_MKFS_OPTIONS_SQUASHFS="-comp zstd -processors $NIX_BUILD_CORES"

    install -Dm0644 ${bootPartitionConfig} repart.d/${bootPartitionConfig.name}
    install -Dm0644 ${dataPartitionConfig} repart.d/${dataPartitionConfig.name}
    install -Dm0644 ${hashPartitionConfig} repart.d/${hashPartitionConfig.name}

    tmp_store=$(mktemp -d)
    nix-store --store $tmp_store --load-db <${toplevelClosure}/registration

    echo "CopyFiles=${coreutils-full}/bin/env:/bin/env" >> repart.d/${dataPartitionConfig.name}
    echo "CopyFiles=''${tmp_store}/nix:/nix" >> repart.d/${dataPartitionConfig.name}
    for path in $(cat ${toplevelClosure}/store-paths); do
      echo "CopyFiles=$path" >> repart.d/${dataPartitionConfig.name}
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

    xz -3 --compress --verbose --threads=$NIX_BUILD_CORES $out/*.{raw,vhdx} $update/*.raw
  '';
}
