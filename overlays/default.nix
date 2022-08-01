inputs: with inputs; {
  default = final: prev: {
    homelab-console-templates = prev.symlinkJoin {
      name = "homelab-console-templates";
      paths = [ ./homelab-console-templates ];
    };
  };
}
