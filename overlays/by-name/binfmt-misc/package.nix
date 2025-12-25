{
  lib,
  pkgsStatic,
  stdenv,
  writeArgcShellApplication,
  util-linux,
}:

writeArgcShellApplication {
  name = "binfmt-misc";
  runtimeInputs = [ util-linux ]; # mount, findmnt
  text = ''
    readonly native_system=${stdenv.hostPlatform.system}
    readonly qemu_user=${pkgsStatic.qemu-user}
  ''
  + lib.fileContents ./binfmt-misc.bash;
}
