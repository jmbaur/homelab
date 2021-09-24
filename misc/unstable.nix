{ config }:
import (builtins.fetchTarball "https://github.com/nixos/nixpkgs/tarball/master") { config = config; }
