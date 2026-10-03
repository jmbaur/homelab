{
  fetchurl,
  gcab,
}:

# Surface UEFI firmware capsule for the Windows Dev Kit 2023 (blackrock).
#
# Microsoft only ships this through Windows Update. The Microsoft Update
# Catalog does not have it, searching by version or by the ESRT GUID finds
# nothing. The download link comes from the WOA Project's mirror of the Windows
# Update driver sets for this device, which they fetch from Windows Update with
# UUPDownload (see refresh.sh in that repo), with one directory per driver set
# version:
# https://github.com/WOA-Project/Qualcomm-Reference-Drivers/tree/master/Surface/8280_BLK
#
# To update, find the newest driver set directory containing surface_uefi.cab
# and pin the commit that added it. The cab contains Surface_UEFI.inf, which
# names the ESRT GUID (UEFI\RES_{...}) and FirmwareVersion that the capsule
# targets, and the capsule itself, Surface_UEFI_<version>.bin.
let
  version = "13.42.235";
in
fetchurl {
  name = "blackrock-uefi-capsule-${version}.bin";
  url = "https://raw.githubusercontent.com/WOA-Project/Qualcomm-Reference-Drivers/87000367581ebaa5eb5491725462a7897e5ea228/Surface/8280_BLK/200.0.14.0/surface_uefi.cab";
  downloadToTemp = true;
  nativeBuildInputs = [ gcab ];
  postFetch = ''
    tmp=$(mktemp -d)
    gcab --extract --directory "$tmp" "$downloadedFile"
    mv "$tmp/Surface_UEFI_${version}.bin" "$out"
  '';
  hash = "sha256-fe6tFH8gnKQN7aGy28hva4aVRd/0Izkh6ya+Es6XVNA=";

  passthru = {
    inherit version;
    # ESRT entry the capsule targets, from Surface_UEFI.inf
    fwClass = "de1c14c2-a438-428d-9ce1-64ca3fabcff3";
    # FirmwareVersion from Surface_UEFI.inf (0x0D002AEB), encoded as
    # major << 24 | minor << 8 | build
    fwVersion = 218114795;
  };
}
