{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  perl,
  perlPackages,
  tayga,
  iproute2,
  iptables,
}:

stdenv.mkDerivation rec {
  pname = "clatd";
  version = "1.6";

  src = fetchFromGitHub {
    owner = "toreanderson";
    repo = "clatd";
    rev = "v${version}";
    hash = "sha256-ZUGWQTXXgATy539NQxkZSvQA7HIWkIPsw1NJrz0xKEg=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = with perlPackages; [
    perl
    NetIP
    NetDNS
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm0755 --target-directory=$out/bin clatd
    patchShebangs $out/bin/clatd
    wrapProgram $out/bin/clatd \
      --set PERL5LIB $PERL5LIB \
      --prefix PATH : ${
        lib.makeBinPath [
          tayga
          iproute2
          iptables
        ]
      }

    runHook postInstall
  '';

  meta = with lib; {
    description = "A 464XLAT CLAT implementation for Linux";
    homepage = "https://github.com/toreanderson/clatd";
    license = licenses.mit;
    maintainers = with maintainers; [ jmbaur ];
    mainProgram = "clatd";
    platforms = platforms.linux;
  };
}
