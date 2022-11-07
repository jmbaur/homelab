{ lib, ... }:
with lib;
{
  # TODO(jared): expand on types.attrs
  options.custom.inventory = mkOption {
    type = types.attrs;
    default = { };
  };
}
