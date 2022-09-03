inputs: with inputs;
{
  default = _: prev: {
    grafana-dashboards = prev.callPackage ./grafana-dashboards { };
  };
}
