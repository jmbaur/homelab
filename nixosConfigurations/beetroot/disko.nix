{
  disk = {
    nvme0n1 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            type = "partition";
            name = "ESP";
            start = "1MiB";
            end = "512MiB";
            fs-type = "fat32";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          {
            name = "luks";
            type = "partition";
            start = "512MiB";
            end = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              content = {
                type = "btrfs";
                mountpoint = "/";
                subvolumes = [ "/" "/nix" "/home" ];
              };
            };
          }
        ];
      };
    };
  };
}
