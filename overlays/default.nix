inputs: with inputs; {
  default = final: prev: {
    grafana-dashboards = prev.callPackage ./grafana-dashboards { };
    ubootCN9130_CF_Pro = prev.callPackage ./ubootCN9130_CF_Pro.nix {
      inherit cn913x_build;
    };
    armTrustedFirmwareCN9130_CF_Pro = prev.callPackage ./armTrustedFirmwareCN9130_CF_Pro.nix {
      inherit (final) ubootCN9130_CF_Pro;
      inherit cn913x_build;
    };
    linuxPackages_cn913x = prev.callPackage ./linuxPackages_cn913x.nix {
      inherit cn913x_build;
    };
    jmbaur-keybase-pgp-keys = prev.fetchurl {
      url = "https://keybase.io/jaredbaur/pgp_keys.asc";
      sha256 = "0rw02akfvdrpdrznhaxsy8105ng5r8xb5mlmjwh9msf4brnbwrj7";
    };
    jmbaur-github-ssh-keys = prev.fetchurl {
      url = "https://github.com/jmbaur.keys";
      sha256 = "0s6j9k9akwzncbz6fqhblj22h96bv31kj90d5019m0p82i3dgl3s";
    };
  };
}
