{ config, lib, ... }:

let
  cfg = config.custom.image;
in
{
  options.custom.image.update = with lib; {
    source = mkOption {
      type = types.str;
      description = ''
        The URL of the remote web server where updates will be fetched from.
      '';
    };

    gpgPubkey = mkOption {
      type = types.path;
      description = ''
        The GPG public key to use for verifying update files. This can be
        generated with `gpg --export <key-name> -a`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."systemd/import-pubring.gpg".source = cfg.update.gpgPubkey;

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
            Type = "url-file";
            Path = cfg.update.source;
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
            Type = "url-file";
            Path = cfg.update.source;
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
