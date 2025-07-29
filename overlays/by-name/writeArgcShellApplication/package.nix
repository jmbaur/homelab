{
  argc,
  lib,
  writeShellApplication,
}:

args:

writeShellApplication (
  lib.recursiveUpdate args {
    derivationArgs = {
      nativeBuildInputs = [ argc ];

      # We put the argc build in postCheck so we don't risk the chance any of
      # the auto-generated argc bash doesn't pass shellcheck.
      postCheck = ''
        argc --argc-build $target $target

        mkdir -p $out/share/man/man1
        argc --argc-mangen $target $out/share/man/man1

        # TODO(jared): completions
      '';
    };
  }
)
