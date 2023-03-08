{ fetchurl
, linkFarm
}:
let
  dashboards = [
    {
      name = "coredns.json";
      options.path = "${./coredns.json}";
    }
  ] ++ (map
    (d: with d; {
      inherit name;
      type = "file";
      options.path = fetchurl {
        inherit url sha256;
        name = "${name}-dashboard.json";
      };
    }) [
    {
      name = "node_exporter_full.json";
      url = "https://grafana.com/api/dashboards/1860/revisions/27/download";
      sha256 = "sha256-PMnH8MfDxlPsSFp5ZYv+C58Qyowdrq4Bog59H3POR84=";
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
