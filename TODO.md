# image based systems
- using systemd-tpm2 cryptsetup token-type doesn't have a nice way to enroll a
  recovery key. Currently it is a manual process of ensuring
  libcryptsetup-token-systemd-tpm2.so is in LD_LIBRARY_PATH and doing
  `cryptsetup luksAddKey --token-id 0 --token-type systemd-tpm2 /path/to/device`.
- add a recovery boot option

# misc
- multicast on celery: see https://forum.turris.cz/t/solved-mdns-avahi-zeroconf-on-bridges-e-g-br-lan/1150

# radish
solve panic on early boot
```
[    1.170372] dw-apb-uart 5000000.serial: Error applying setting, reverse things back
[    1.180728] sun6i-spi 5010000.spi: Error applying setting, reverse things back
[    3.235612] i2c i2c-0: mv64xxx: I2C bus locked, block: 1, time_left: 0
[    3.242755] axp20x-i2c 0-0036: Failed to set masks in 0x20: -110
[    3.249298] axp20x-i2c 0-0036: failed to add irq chip: -110
[    3.255472] axp20x-i2c 0-0036: probe with driver axp20x-i2c failed with error -110
[    3.279718] dw-apb-uart 5000000.serial: Error applying setting, reverse things back
[    3.289991] sun6i-spi 5010000.spi: Error applying setting, reverse things back
[    3.314332] dw-apb-uart 5000000.serial: Error applying setting, reverse things back
[    3.324627] sun6i-spi 5010000.spi: Error applying setting, reverse things back
```
