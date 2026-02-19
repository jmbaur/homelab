# general
- recovery key enrollment

# desktop
- use https://github.com/ylxdzsw/dssd for org.freedesktop.secrets implementation

# misc
- multicast on celery: see https://forum.turris.cz/t/solved-mdns-avahi-zeroconf-on-bridges-e-g-br-lan/1150

# celery
solve issues at early boot

```
[    0.527711] mtk-socinfo mtk-socinfo.0.auto: error -ENOENT: Failed to get socinfo data
[    0.527816] mtk-socinfo mtk-socinfo.0.auto: probe with driver mtk-socinfo failed with error -2
[    1.266381] mtk_soc_eth 15100000.ethernet: generated random MAC address ba:1c:62:2c:c5:c5
[    1.781750] mt7986a-pinctrl 1001f000.pinctrl: pin GPIO_4 already requested by 11280000.pcie; cannot claim for pinctrl_moore:521
[    1.793267] mt7986a-pinctrl 1001f000.pinctrl: error -EINVAL: pin-9 (pinctrl_moore:521)
[    1.801186] gpio-keys gpio-keys: error -EINVAL: failed to get gpio
[    1.807369] gpio-keys gpio-keys: probe with driver gpio-keys failed with error -22
```

```
Jan 12 02:12:48 celery kernel: mtdblock: MTD device 'reserved' is NAND, please consider using UBI block devices instead.
Jan 12 02:12:48 celery kernel: mtdblock: MTD device 'bl2' is NAND, please consider using UBI block devices instead.
Jan 12 02:12:48 celery kernel: mtdblock: MTD device 'ubi' is NAND, please consider using UBI block devices instead.
Jan 12 02:12:48 celery kernel: mtdblock: MTD device 'fip' is NAND, please consider using UBI block devices instead.
```

solve reboot issues (hangs indefinitely) https://freedesktop.org/wiki/Software/systemd/Debugging/#diagnosingshutdownproblems

```
[  OK  ] Removed slice Slice /system/systemd-zram-setup.
[  OK  ] Reached target System Shutdown.
[  OK  ] Reached target Late Shutdown Services.
[  OK  ] Finished System Reboot.
[  OK  ] Reached target System Reboot.
[   36.395811] watchdog: watchdog0: watchdog did not stop!
[   36.640219] watchdog: watchdog0: watchdog did not stop!
[   37.056180] watchdog: watchdog0: watchdog did not stop!
[   37.084829] reboot: Restarting system
```

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

# pumpkin

Recovery image doesn't work without kernel modules that allow for USB mass storage access into initrd, meaning we must put the recovery image on an sdcard or something similar.

# bootloader installer

On some systems, the only python dependency is the `systemd-boot-builder.py` script.
If we implement this ourselves, we can get rid of this dependency as well as implement some features that have yet to be implemented upstream (e.g. boot counting).

# filesystem shenanigans

For multi-disk systems, it would probably be best to have the non root-filesystem disk not mounted somewhere like /var, such that if the disk were to fail, we wouldn't be able to boot past the initrd.

# updating

Take inspiration from https://determinate.systems/posts/hydra-deployment-source-of-truth/
