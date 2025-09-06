{ lib, formats }:

(formats.json { }).generate "homelab-network.json" (
  import ../../../nixos-modules/server/network.nix { inherit lib; }
)
