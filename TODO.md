# image based systems
- Add a way to add trusted user on first boot, see:
  https://github.com/systemd/systemd/blob/main/units/systemd-homed-firstboot.service
- creating a minimized base image whose partitions can be resized on first-boot
  seems not to work
- using systemd-tpm2 cryptsetup token-type doesn't have a nice way to enroll a
  recovery key. Currently it is a manual process of ensuring
  libcryptsetup-token-systemd-tpm2.so is in LD_LIBRARY_PATH and doing
  `cryptsetup luksAddKey --token-id 0 --token-type systemd-tpm2 /path/to/device`.
