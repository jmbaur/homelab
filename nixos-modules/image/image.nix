{ stdenv
, runCommand
, fakeroot
, systemd
, zstd
, formats
, closureInfo
, e2fsprogs
, squashfsTools
, erofs-utils
, dosfstools
, mtools
, jq
, sbsigntool

  # arguments
, bootPartition
, dataPartition
, hashPartition
, toplevel
, bootFileCommands
}:

let
  seed = "39c4020e-af73-434a-93e4-7e37fdcc7f96";

  systemdArchitecture = builtins.replaceStrings [ "_" ] [ "-" ] stdenv.hostPlatform.linuxArch;
  closure = closureInfo { rootPaths = [ toplevel ]; };

  bootPartitionConfig = (formats.ini { }).generate "boot.conf" { Partition = bootPartition; };
  dataPartitionConfig = (formats.ini { }).generate "data.conf" { Partition = dataPartition; };
  hashPartitionConfig = (formats.ini { }).generate "hash.conf" { Partition = hashPartition; };
in
runCommand "nixos-image"
{
  nativeBuildInputs = [
    fakeroot
    systemd
    zstd
    e2fsprogs
    squashfsTools
    erofs-utils
    dosfstools
    mtools
    jq
    sbsigntool
  ];
  inherit bootFileCommands;
  passAsFile = [ "bootFileCommands" ];
} ''
  install -Dm0644 ${bootPartitionConfig} repart.d/boot.conf
  install -Dm0644 ${dataPartitionConfig} repart.d/data.conf
  install -Dm0644 ${hashPartitionConfig} repart.d/hash.conf

  echo "CopyFiles=${closure}/registration:/nix-path-registration" >> repart.d/data.conf
  for path in $(cat ${closure}/store-paths); do
    echo "CopyFiles=$path:''${path#/nix/store}" >> repart.d/data.conf
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

  for line in $(bash "$bootFileCommandsPath"); do
    echo "CopyFiles=$line" >> repart.d/boot.conf
  done

  fakeroot systemd-repart ''${repart_args[@]} \
    $out/image.raw

  zstd --rm $out/*.raw
''
