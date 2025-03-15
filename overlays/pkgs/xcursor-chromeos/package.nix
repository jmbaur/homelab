# https://aur.archlinux.org/packages/xcursor-chromeos

{
  fetchurl,
  stdenvNoCC,
  xorg,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "xcursor-chromeos";
  version = "136.0.7068.1";

  src = fetchurl {
    url = "https://chromium.googlesource.com/chromium/src/+archive/${finalAttrs.version}/ui/resources.tar.gz";
    hash = "sha256-RZJK6XihlOPVxGBQVryi+kcWEX7n6nr9JEkX3qs2D0k=";
  };

  sourceRoot = ".";

  dontConfigure = true;

  nativeBuildInputs = [ xorg.xcursorgen ];

  makeFlags = [ "-f ${./Makefile}" ];

  preBuild = ''
    _prepare_list=(
      "alias alias"
      "cell cell"
      "context_menu context_menu"
      "copy copy"
      "crosshair crosshair"
      "fleur hand1"
      "hand2 hand2"
      "hand3 grabbing"
      "help help"
      "left_ptr left_ptr"
      "move move"
      "nodrop nodrop"
      "sb_horizontal_double_arrow sb_h_double_arrow"
      "sb_vertical_double_arrow sb_v_double_arrow"
      "top_left_corner top_left_corner"
      "top_right_corner top_right_corner"
      "xterm xterm"
      "xterm_horiz xterm_horiz"
      "zoom_in zoom_in"
      "zoom_out zoom_out"
    )

    _package_list=(
      "alias dnd-link"
      "crosshair cross"
      "grabbing fleur"
      "grabbing pointer-move"
      "grabbing dnd-move"
      "hand1 grab"
      "hand2 hand"
      "hand2 pointer"
      "help left_ptr_help"
      "left_ptr all-scroll"
      "left_ptr arrow"
      "left_ptr default"
      "left_ptr wait"
      "left_ptr watch"
      "nodrop no-drop"
      "nodrop dnd-no-drop"
      "sb_h_double_arrow e-resize"
      "sb_h_double_arrow ew-resize"
      "sb_h_double_arrow h_double_arrow"
      "sb_h_double_arrow left_side"
      "sb_h_double_arrow right_side"
      "sb_h_double_arrow w-resize"
      "sb_v_double_arrow bottom_side"
      "sb_v_double_arrow n-resize"
      "sb_v_double_arrow ns-resize"
      "sb_v_double_arrow s-resize"
      "sb_v_double_arrow row-resize"
      "sb_v_double_arrow top_side"
      "sb_v_double_arrow v_double_arrow"
      "top_right_corner bd_double_arrow"
      "top_left_corner bottom_right_corner"
      "top_left_corner nw-resize"
      "top_left_corner se-resize"
      "top_right_corner bottom_left_corner"
      "top_right_corner fd_double_arrow"
      "top_right_corner ne-resize"
      "top_right_corner sw-resize"
      "xterm text"
    )

    for pair in "''${_prepare_list[@]}"; do
      read -r src dst <<< "$pair"
      mv "default_100_percent/common/pointers/$src.png" "''${dst}_25.png"
      mv "default_200_percent/common/pointers/$src.png" "''${dst}_50.png"
    done
  '';

  installPhase = ''
    runHook preInstall

    for pair in "''${_package_list[@]}"; do
      read -r src dst <<< "$pair"
      install -D -m0644 -t "$out/share/icons/$pname/cursors/" "$src"
      ln -s "$src" "$out/share/icons/$pname/cursors/$dst"
    done

    runHook postInstall
  '';
})
