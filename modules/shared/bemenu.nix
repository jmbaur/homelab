{ lib, ... }:
with lib; {
  BEMENU_OPTS = escapeShellArgs [
    "--ignorecase"
    "--fn=JetBrains Mono"
    "--line-height=30"
  ];
}
