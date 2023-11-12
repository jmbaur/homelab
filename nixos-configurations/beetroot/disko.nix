{
  disko.devices = {
    disk = {
      nvme0n1 = {
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                  };
                };
              };
              # name = "luks";
              # start = "512MiB";
              # end = "100%";
              # content = {
              #   type = "luks";
              #   name = "cryptroot";
              #   passwordFile = "/tmp/secret.key";
              #   content = {
              #     type = "btrfs";
              #     subvolumes = {
              #       "@" = {
              #         mountpoint = "/";
              #         mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
              #       };
              #       "@nix" = {
              #         mountpoint = "/nix";
              #         mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
              #       };
              #       "@home" = {
              #         mountpoint = "/home";
              #         mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
              #       };
              #     };
              #   };
              # };
            };
          };
        };
      };
    };
  };
}
