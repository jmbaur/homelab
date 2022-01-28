self: super: {
  chromium = super.chromium.override {
    commandLineArgs = "--ozone-platform-hint=auto --force-dark-mode --enable-features=WebUIDarkMode";
  };
}
