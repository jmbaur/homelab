{
  lib,
  fetchFromGitHub,
  buildDotnetModule,
}:

buildDotnetModule {
  pname = "avsdk";
  version = "0-unstable-2024-07-10";

  src = fetchFromGitHub {
    owner = "thesofproject";
    repo = "avsdk";
    rev = "e1176e63ccbee51ab59fdb8afaed2bf5af8427d1";
    hash = "sha256-nDQ/UJz3JgVxPYkC1Lautu+bXsO+umt0qHkG9uCwTW0=";
  };

  projectFile = [
    "avstplg/avstplg.sln"
    "probe2wav/probe2wav.sln"
  ];

  meta = {
    description = "SDK for Intel audio software solutions";
    homepage = "https://github.com/thesofproject/avsdk";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.jmbaur ];
    mainProgram = "avsdk";
    platforms = lib.platforms.all;
  };
}
