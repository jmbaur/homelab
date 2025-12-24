{
  lib,
  pkgsStatic,
  stdenv,
  writeArgcShellApplication,
}:

writeArgcShellApplication {
  name = "binfmt-misc";
  text = ''
    readonly native_system=${stdenv.hostPlatform.system}
    readonly qemu_user=${pkgsStatic.qemu-user}
  ''
  + lib.fileContents ./binfmt-misc.bash;
}
