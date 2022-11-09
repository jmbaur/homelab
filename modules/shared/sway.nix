{
  extraSessionCommands = ''
    # SDL:
    export SDL_VIDEODRIVER=wayland
    # QT (needs qt5.qtwayland in systemPackages):
    export QT_QPA_PLATFORM=wayland-egl
    # Fix for some Java AWT applications (e.g. Android Studio), use this if
    # they aren't displayed properly:
    export _JAVA_AWT_WM_NONREPARENTING=1
  '';
  wrapperFeatures = {
    base = true;
    gtk = true;
  };
}
