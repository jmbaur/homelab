# TODO(jared): this file is VERY similar to ../image.nix, we should just make
# that file modular enough to work in this case as well.

{
  dosfstools,
  dtc,
  e2fsprogs,
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
  mainImage,
  bootFileCommands,
  imageName,
  postImageCommands,
  sectorSize,
}:

let
  iniFormat = formats.ini { };

  seed = "aaf32ba8-a2d3-4ff2-98af-c37030291277";

  bootPartition = {
    Type = "esp";
    Label = "BOOT";
    Format = "vfat";
    SizeMinBytes = "256M";
    SizeMaxBytes = "256M";
  };

  imagePartition = {
    Type = "linux-generic";
    Label = "installer";
    Format = "ext4";
    CopyFiles = "${mainImage}:/image";
    Minimize = "guess";
  };

  systemdArchitecture = builtins.replaceStrings [ "_" ] [ "-" ] stdenv.hostPlatform.linuxArch;

  bootPartitionConfig = iniFormat.generate "10-boot.conf" { Partition = bootPartition; };
  imagePartitionConfig = iniFormat.generate "20-image.conf" { Partition = imagePartition; };
in
stdenv.mkDerivation {
  name = "nixos-image-${imageName}-installer";

  depsBuildBuild = [
    dosfstools
    dtc
    e2fsprogs
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

  buildCommand = ''
    install -Dm0644 ${bootPartitionConfig} repart.d/${bootPartitionConfig.name}
    install -Dm0644 ${imagePartitionConfig} repart.d/${imagePartitionConfig.name}

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

    xz -3 --compress --verbose --threads=0 $out/*.{raw,vhdx}
  '';
}
