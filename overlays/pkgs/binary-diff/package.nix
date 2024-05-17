{
  writeShellApplication,
  xxd,
  neovim,
}:
writeShellApplication {
  name = "binary-diff";
  runtimeInputs = [
    xxd
    neovim
  ];
  text = ''

    tmp=$(mktemp -d)
    trap 'rm -rf $tmp' EXIT
    pushd "$tmp" 2>/dev/null || exit 1
    file1=$(basename "$1").hex
    file2=$(basename "$2").hex
    echo "$file1 $file2"
    xxd -R never "$1" >"$file1"
    xxd -R never "$2" >"$file2"

    nvim -d "$file1" "$file2"

    popd 2>/dev/null || exit 1
  '';
}
