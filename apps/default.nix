inputs: with inputs; nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (system:
  let
    pkgs = import nixpkgs { inherit system; };
  in
  {
    bootstrap-beetroot = {
      type = "app";
      program =
        let
          program = pkgs.writeShellApplication {
            name = "bootstrap-beetroot";
            runtimeInputs = with pkgs; [ yq-go ];
            text = builtins.readFile ../nixosConfigurations/beetroot/bootstrap.bash;
          };
        in
        "${program}/bin/bootstrap-beetroot";
    };
  })
