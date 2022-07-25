{ lib, ... }: with lib; {
  options.router = {
    guaPrefix = mkOption { type = types.str; };
    ulaPrefix = mkOption { type = types.str; };
  };
}
