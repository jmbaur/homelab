{ ... }: {
  services.ntp = {
    enable = true;
    extraConfig = ''
      listen on *
    '' +
    # continue to serve time to the network in case internet access is lost
    ''
      tos orphan 15
    '';
  };
}
