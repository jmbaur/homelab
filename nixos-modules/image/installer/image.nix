# TODO(jared): this file is VERY similar to ../image.nix, we should just make
# that file modular enough to work in this case as well.

{
  dosfstools,
  dtc,
  e2fsprogs,
  fakeroot,
  formats,
  jq,
  mtools,
  sbsigntool,
  stdenv,
  systemd,
  systemdUkify,
  xz,

  # arguments
  bootFileCommands,
  imageName,
  postImageCommands ? "",
  sectorSize,
}:

let
  iniFormat = formats.ini { };

  seed = "aaf32ba8-a2d3-4ff2-98af-c37030291277";

  bootPartition = {
    Type = "esp";
    Label = "INSTALLER";
    Format = "vfat";
    SizeMinBytes = "256M";
    SizeMaxBytes = "256M";
  };

  systemdArchitecture = builtins.replaceStrings [ "_" ] [ "-" ] stdenv.hostPlatform.linuxArch;

  bootPartitionConfig = iniFormat.generate "10-boot.conf" { Partition = bootPartition; };
in
stdenv.mkDerivation {
  name = "nixos-image-${imageName}-installer";

  depsBuildBuild = [
    dosfstools
    dtc
    e2fsprogs
    fakeroot
    jq
    mtools
    sbsigntool
    systemd
    systemdUkify
    xz
  ];

  bootFileCommands =
    ''
      # source the setup file to get access to `substituteInPlace`
      source $stdenv/setup
    ''
    + bootFileCommands;
  passAsFile = [ "bootFileCommands" ];

  buildCommand = ''
    install -Dm0644 ${bootPartitionConfig} repart.d/${bootPartitionConfig.name}

    repart_args=(
      "--dry-run=no"
      "--architecture=${systemdArchitecture}"
      "--seed=${seed}"
      "--sector-size=${toString sectorSize}"
      "--definitions=./repart.d"
      "--json=pretty"
    )

    mkdir -p $out

    export bootfiles=bootfiles
    bash "$bootFileCommandsPath"
    for line in $(cat $bootfiles); do
      echo "copying boot file $line"
      echo "CopyFiles=$line" >> repart.d/${bootPartitionConfig.name}
    done

    fakeroot systemd-repart ''${repart_args[@]} \
      --empty=create \
      --size=auto \
      $out/image.raw

    ${postImageCommands}

    xz -3 --compress --verbose --threads=$NIX_BUILD_CORES $out/*
  '';
}
