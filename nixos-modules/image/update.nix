{ config, lib, ... }:

let
  cfg = config.custom.image;
in
{
  config = lib.mkIf cfg.enable {
    systemd.sysupdate = {
      enable = true;

      # placeholder meanings:
      # %o -> operating system ID (e.g. "nixos")
      # @v -> version
      # @u -> partition UUID
      # @a -> set SD_GPT_FLAG_NO_AUTO partition flag
      # @r -> set SD_GPT_FLAG_READ_ONLY partition flag
      transfers = {
        "50-verity" = {
          Transfer.ProtectVersion = "%A";
          Source = {
            Type = "regular-file";
            Path = "/run/update";
            MatchPattern = "%o_@v_@u_@a_@r.usr-hash.raw.xz";
          };
          Target = {
            Type = "partition";
            Path = "auto";
            MatchPattern = "usr-hash-@v";
            MatchPartitionType = "usr-verity";
            InstancesMax = 2;
          };
        };
        "60-usr" = {
          Transfer.ProtectVersion = "%A";
          Source = {
            Type = "regular-file";
            Path = "/run/update";
            MatchPattern = "%o_@v_@u_@a_@r.usr.raw.xz";
          };
          Target = {
            Type = "partition";
            Path = "auto";
            MatchPattern = "usr-@v";
            MatchPartitionType = "usr";
            InstancesMax = 2;
          };
        };
      };
    };
  };
}

