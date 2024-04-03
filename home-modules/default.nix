inputs: {
  jared = {
    imports = [ ./jared ];
    _module.args = {
      inherit inputs;
    };
  };
}
