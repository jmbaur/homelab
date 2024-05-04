{
  dosfstools,
  dtc,
  erofs-utils,
  fakeroot,
  formats,
  jq,
  mtools,
  sbsigntool,
  stdenv,
  systemd,
  systemdUkify,
  ubootTools,
  xz,

  # arguments
  bootFileCommands,
  closure,
  id,
  imageName,
  isUpdate ? false,
  partitions,
  postImageCommands,
  sectorSize,
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
    Verity = "hash";
    VerityMatchKey = "usr";
    SplitName = "usr-hash";
  };

  systemdArchitecture = builtins.replaceStrings [ "_" ] [ "-" ] stdenv.hostPlatform.linuxArch;

  bootPartitionConfig = iniFormat.generate "10-boot.conf" { Partition = bootPartition; };
  dataPartitionConfig = iniFormat.generate "20-usr-a.conf" { Partition = dataPartition; };
  hashPartitionConfig = iniFormat.generate "20-usr-hash-a.conf" { Partition = hashPartition; };
in
stdenv.mkDerivation {
  name = "nixos-image-${imageName}";

  depsBuildBuild = [
    dosfstools
    dtc
    erofs-utils
    fakeroot
    jq
    mtools
    sbsigntool
    systemd
    systemdUkify
    ubootTools
    xz
  ];

  bootFileCommands =
    ''
      # source the setup file to get access to `substituteInPlace`
      source $stdenv/setup
    ''
    + bootFileCommands;
  passAsFile = [ "bootFileCommands" ];

  env.SYSTEMD_REPART_MKFS_OPTIONS_EROFS = "-zlz4hc,12";

  buildCommand = ''
    install -Dm0644 ${bootPartitionConfig} repart.d/${bootPartitionConfig.name}
    install -Dm0644 ${dataPartitionConfig} repart.d/${dataPartitionConfig.name}
    install -Dm0644 ${hashPartitionConfig} repart.d/${hashPartitionConfig.name}

    echo "CopyFiles=${closure}/registration:/.nix-path-registration" >> repart.d/${dataPartitionConfig.name}
    for path in $(cat ${closure}/store-paths); do
      echo "CopyFiles=$path:''${path#/nix/store}" >> repart.d/${dataPartitionConfig.name}
    done

    repart_args=(
      "--dry-run=no"
      "--architecture=${systemdArchitecture}"
      "--seed=${seed}"
      "--sector-size=${toString sectorSize}"
      "--definitions=./repart.d"
      "--json=pretty"
    )

    mkdir -p $out

    fakeroot systemd-repart ''${repart_args[@]} \
      --defer-partitions=esp \
      --empty=create \
      --size=auto \
      --split=${if isUpdate then "yes" else "no"} \
      $out/image.raw | tee repart-output.json

    export usrhash=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .roothash' <repart-output.json)

    export bootfiles=bootfiles
    bash "$bootFileCommandsPath"
    for line in $(cat $bootfiles); do
      echo "copying boot file $line"
      echo "CopyFiles=$line" >> repart.d/${bootPartitionConfig.name}
    done

    fakeroot systemd-repart ''${repart_args[@]} $out/image.raw

    ${postImageCommands}

    ${
      if isUpdate then
        ''
          data_uuid=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .uuid' <repart-output.json)
          hash_uuid=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}-verity") | .uuid' <repart-output.json)
          data_orig_path=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}") | .split_path' <repart-output.json)
          hash_orig_path=$(jq --raw-output '.[] | select(.type == "usr-${systemdArchitecture}-verity") | .split_path' <repart-output.json)
          data_new_path="''${out}/${id}_${version}_''${data_uuid}.usr.raw"
          hash_new_path="''${out}/${id}_${version}_''${hash_uuid}.usr-hash.raw"
          mv "$data_orig_path" "$data_new_path"
          mv "$hash_orig_path" "$hash_new_path"
          find $out -name 'image.*' -exec rm -r {} \;
        ''
      else
        ''
          find $out -not -name 'image.*' -exec rm -r {} \;
        ''
    }

    xz -3 --compress --verbose --threads=0 $out/*.{raw,vhdx}
  '';
}
