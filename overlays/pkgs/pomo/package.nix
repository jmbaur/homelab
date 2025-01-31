{ rustPlatform, runCommand }:

rustPlatform.buildRustPackage rec {
  pname = "pomo";
  version = "0.1.0";

  cargoVendorDir = "vendor";

  src = runCommand "${pname}-src" { } ''
    mkdir -p $out/{vendor,src}

    cp ${./pomo.rs} $out/src/main.rs

    cat >$out/Cargo.toml <<EOF
    [package]
    name = "${pname}"
    version = "${version}"
    edition = "2021"
    EOF

    cat >$out/Cargo.lock <<EOF
    version = 3
    [[package]]
    name = "${pname}"
    version = "${version}"
    EOF
  '';

  meta.mainProgram = "pomo";
}
