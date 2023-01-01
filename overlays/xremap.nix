{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.7.15";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-Is/5fySlGm2XGVLbI+3TIZG3Nr5v5bEMoEckP9ZWh+0=";
  };
  cargoSha256 = "sha256-Qond7/gBw8RgoaWdp6z7Hk4SvwSEe81imptuvx1KcaU=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
