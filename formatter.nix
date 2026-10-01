inputs:
inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:
  pkgs.treefmt.withConfig {
    runtimeInputs = [
      pkgs.deadnix
      pkgs.fnlfmt
      pkgs.nixfmt
      pkgs.prettier
      pkgs.schemat
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.statix
      pkgs.zig_0_16
    ];

    settings = {
      on-unmatched = "info";

      formatter.nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };

      formatter.deadnix = {
        command = "deadnix";
        includes = [ "*.nix" ];
        options = [ "--edit" ];
      };

      formatter.prettier = {
        command = "prettier";
        includes = [ "*.html" ];
        options = [ "--write" ];
      };

      formatter.statix = {
        command = pkgs.writeShellScript "statix-fix" ''
          for file in "$@"; do
            statix fix "$file"
          done
        '';
        includes = [ "*.nix" ];
      };

      # Disabled in favor of the editor's lisp indentation.
      formatter.schemat = inputs.nixpkgs.lib.mkIf false {
        command = "schemat";
        includes = [
          "*.egg"
          "*.scm"
        ];
      };

      formatter.shell = {
        command = "shfmt";
        options = [
          "-w"
          "-s"
        ];
        includes = [
          "*.sh"
          "*.bash"
          "*.envrc"
          "*.envrc.*"
        ];
      };

      formatter.shellcheck = {
        command = "shellcheck";
        includes = [
          "*.sh"
          "*.bash"
          "*.envrc"
          "*.envrc.*"
        ];
      };

      formatter.fennel = {
        command = "fnlfmt";
        options = [ "--fix" ];
        includes = [ "*.fnl" ];
      };

      formatter.zig = {
        command = "zig";
        options = [ "fmt" ];
        includes = [ "*.zig" ];
      };
    };
  }
) inputs.self.legacyPackages
