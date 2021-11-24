self: super: {
  chromium = super.chromium.override {
    commandLineArgs = [ "--enable-features=UseOzonePlatform" "--ozone-platform=wayland" ];
  };
}

