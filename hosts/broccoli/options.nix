{ config, lib, pkgs, ... }: {
  options = {
    router = {
      guaPrefix = lib.mkOption {
        type = lib.types.str;
      };
      ulaPrefix = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

}
