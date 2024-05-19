{ writers }: writers.writeRustBin "macgen" { } (builtins.readFile ./macgen.rs)
