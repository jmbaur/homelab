{ writers }: writers.writeRustBin "pomo" { } (builtins.readFile ./pomo.rs)
