{ writeShellScriptBin, curl }:
writeShellScriptBin "pb" "echo $(${curl}/bin/curl --silent --data-binary @- https://paste.rs/)"
