# image based systems
- using systemd-tpm2 cryptsetup token-type doesn't have a nice way to enroll a
  recovery key. Currently it is a manual process of ensuring
  libcryptsetup-token-systemd-tpm2.so is in LD_LIBRARY_PATH and doing
  `cryptsetup luksAddKey --token-id 0 --token-type systemd-tpm2 /path/to/device`.
- add a recovery boot option

# misc
- multicast on celery: see https://forum.turris.cz/t/solved-mdns-avahi-zeroconf-on-bridges-e-g-br-lan/1150
