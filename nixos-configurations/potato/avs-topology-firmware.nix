{
  fetchFromGitHub,
  avsdk,
  alsa-utils,
  runCommand,
}:

runCommand "hda-8086280b-tplg-firmware"
  {
    src = fetchFromGitHub {
      owner = "thesofproject";
      repo = "avs-topology-xml";
      rev = "v2024.02";
      hash = "sha256-/OqyHBoe3KXQM/ixzEKNSNRFjyHyiw+QNNVAxWmlW0o=";
    };
    nativeBuildInputs = [
      avsdk
      alsa-utils
    ];
  }
  ''
    install $src/hdmi/hda-8086280b-tplg.xml 0
    avstplg -c 0 -o 1
    alsatplg -c 1 -o 2
    install -Dm0444 2 $out/lib/firmware/intel/avs/hda-8086280b-tplg.bin
  ''
