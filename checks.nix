inputs: with inputs; builtins.mapAttrs
  (system: deployLib: deployLib.deployChecks self.deploy)
  deploy-rs.lib
