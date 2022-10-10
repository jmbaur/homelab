inputs: with inputs; builtins.mapAttrs
  (_: deployLib: deployLib.deployChecks self.deploy)
  deploy-rs.lib
