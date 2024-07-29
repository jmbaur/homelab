{
  writeShellApplication,
  xxd,
  vim,
}:
writeShellApplication {
  name = "binary-diff";
  runtimeInputs = [
    xxd
    vim
  ];
  text = ''
    file1=$(realpath "$1")
    file2=$(realpath "$2")

    tmp=$(mktemp -d)
    trap 'rm -rf $tmp' EXIT
    pushd "$tmp" >/dev/null || exit 1

    hex1=$(basename "$file1").hex
    hex2=$(basename "$file2").hex

    echo "$file1 $file2"
    xxd -R never "$file1" >"$hex1"
    xxd -R never "$file2" >"$hex2"

    vimdiff "$hex1" "$hex2"

    popd >/dev/null || exit 1
  '';
}
