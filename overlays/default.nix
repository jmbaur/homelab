inputs: with inputs;
{
  default = _: prev: {
    grafana-dashboards = prev.callPackage ./grafana-dashboards { };
    jmbaur-keybase-pgp-keys = builtins.fetchurl {
      url = "https://keybase.io/jaredbaur/pgp_keys.asc";
      sha256 = "0rw02akfvdrpdrznhaxsy8105ng5r8xb5mlmjwh9msf4brnbwrj7";
    };
    jmbaur-github-ssh-keys = builtins.fetchurl {
      url = "https://github.com/jmbaur.keys";
      sha256 = "0s6j9k9akwzncbz6fqhblj22h96bv31kj90d5019m0p82i3dgl3s";
    };
  };
}
