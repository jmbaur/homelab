{ config, lib, ... }:

let
  cfg = config.custom.image;
in
{
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.settings."10-update"."/run/update".d = { };

    systemd.sysupdate = {
      enable = true;

      # placeholder meanings:
      # %o -> operating system ID (e.g. "nixos")
      # @v -> version
      # @u -> partition UUID
      transfers = {
        "50-verity" = {
          Transfer.ProtectVersion = "%A";
          Source = {
            Type = "regular-file";
            Path = "/run/update";
            MatchPattern = "%o_@v_@u.usr-hash.raw.xz";
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
            MatchPattern = "%o_@v_@u.usr.raw.xz";
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
