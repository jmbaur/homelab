{ fetchurl
, linkFarm
}:
let
  dashboards = [
    {
      name = "coredns.json";
      options.path = "${./coredns.json}";
    }
    {
      name = "wireguard.json";
      options.path = "${./wireguard.json}";
    }
  ] ++ (map
    (d: with d; {
      inherit name;
      options.path = fetchurl {
        inherit url sha256;
        name = "${name}-dashboard.json";
      };
    }) [
    {
      "name" = "node_exporter_full.json";
      "url" = "https://grafana.com/api/dashboards/1860/revisions/27/download";
      "sha256" = "16srb69lhysqvkkwf25d427dzg4p2fxr1igph9j8aj9q4kkrw595";
    }
  ]);
in
(linkFarm "grafana-dashboards" (map
  (d: {
    inherit (d) name; path = d.options.path;
  })
  dashboards)).overrideAttrs (_: {
  passthru = { inherit dashboards; };
})
