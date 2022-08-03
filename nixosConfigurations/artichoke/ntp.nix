{ ... }: {
  services.ntp = {
    enable = true;
    # continue to serve time to the network in case internet access is lost
    extraConfig = ''
      tos orphan 15
    '';
  };
}
