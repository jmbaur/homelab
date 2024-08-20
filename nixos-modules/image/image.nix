{
  closureInfo,
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
  runCommand,
  sbsigntool,
  sqlite,
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
  rootPaths,
  usrFormat,
  version,
  maxUsrPadding,
  maxUsrHashPadding,
}:

let
  iniFormat = formats.ini { };

  seed = "39c4020e-af73-434a-93e4-7e37fdcc7f96";

  bootPartition = partitions."10-boot" // { };

  dataPartition = partitions."11-usr-a" // {
    PaddingMinBytes = toString maxUsrPadding;
    PaddingMaxBytes = toString maxUsrPadding;
    Minimize = true;
    Format = usrFormat;
    Verity = "data";
    VerityMatchKey = "usr";
    SplitName = "usr";
  };

  hashPartition = partitions."11-usr-hash-a" // {
    PaddingMinBytes = toString maxUsrHashPadding;
    PaddingMaxBytes = toString maxUsrHashPadding;
    Minimize = true;
    Verity = "hash";
    VerityMatchKey = "usr";
    SplitName = "usr-hash";
  };

  systemdArchitecture = lib.replaceStrings [ "_" ] [ "-" ] stdenv.hostPlatform.linuxArch;

  bootPartitionConfig = iniFormat.generate "10-boot.conf" { Partition = bootPartition; };
  dataPartitionConfig = iniFormat.generate "11-usr-a.conf" { Partition = dataPartition; };
  hashPartitionConfig = iniFormat.generate "11-usr-hash-a.conf" { Partition = hashPartition; };

  closure = closureInfo { inherit rootPaths; };

  roNixState =
    runCommand "read-only-nix-state"
      {
        nativeBuildInputs = [
          sqlite
          nix
        ];
      }
      ''
        export NIX_REMOTE=local?root=$out
        # A user is required by nix
        # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
        export USER=nobody
        nix-store --load-db <${closure}/registration
        # Reset registration times to make the image reproducible
        sqlite3 "$out/nix/var/nix/db/db.sqlite" "UPDATE ValidPaths SET registrationTime = ''${SOURCE_DATE_EPOCH}"
      '';

  repartDefinitions = runCommand "repart-definitions" { } ''
    install -Dm0644 ${bootPartitionConfig} $out/${bootPartitionConfig.name}
    install -Dm0644 ${dataPartitionConfig} $out/${dataPartitionConfig.name}
    install -Dm0644 ${hashPartitionConfig} $out/${hashPartitionConfig.name}

    echo "CopyFiles=${coreutils-full}/bin/env:/bin/env" >> $out/${dataPartitionConfig.name}
    echo "CopyFiles=${roNixState}/nix:/nix" >> $out/${dataPartitionConfig.name}
    for path in $(cat ${closure}/store-paths); do
      echo "CopyFiles=$path" >> $out/${dataPartitionConfig.name}
    done
  '';
in
stdenv.mkDerivation {
  name = "nixos-image-${imageName}";

  passthru = {
    inherit repartDefinitions;
  };

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

  outputs = [
    "out"
    "update"
  ];

  buildCommand = ''
    export SYSTEMD_REPART_MKFS_OPTIONS_EROFS="-zlz4hc,12 -T0"
    export SYSTEMD_REPART_MKFS_OPTIONS_SQUASHFS="-comp zstd -processors $NIX_BUILD_CORES"

    install -Dm0644 -t repart.d ${repartDefinitions}/*

    repart_args=(
      "--dry-run=no"
      "--architecture=${systemdArchitecture}"
      "--seed=${seed}"
      "--sector-size=${toString sectorSize}"
      "--definitions=repart.d"
      "--json=pretty"
    )

    mkdir -p $out $update
    echo ${version} > $update/version

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
