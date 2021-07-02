{ config, pkgs, ... }: {
  home-manager.users.jared.home.file.".psqlrc".text = ''
    \set HISTCONTROL ignoredups
    \set COMP_KEYWORD_CASE upper
    \setenv PAGER 'pspg -bX --no-mouse'

    \set QUIET 1
    \pset linestyle unicode
    \pset border 2
    \pset null NULL
    \unset QUIET
  '';
}
