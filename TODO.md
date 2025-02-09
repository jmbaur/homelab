# general
- recovery key enrollment

# desktop
- use https://github.com/ylxdzsw/dssd for org.freedesktop.secrets implementation

# misc
- multicast on celery: see https://forum.turris.cz/t/solved-mdns-avahi-zeroconf-on-bridges-e-g-br-lan/1150

# celery
solve issues at early boot
```
[    1.040264] mtk-socinfo mtk-socinfo.0.auto: error -ENOENT: Failed to get socinfo data
[    1.040283] mtk-socinfo mtk-socinfo.0.auto: probe with driver mtk-socinfo failed with error -2
[    1.621437] mtk_soc_eth 15100000.ethernet: generated random MAC address a2:2e:66:56:42:6b
[    1.926205] mtk-pcie-gen3 11280000.pcie: PCIe link down, current LTSSM state: detect.quiet (0x1)
[    1.935009] mtk-pcie-gen3 11280000.pcie: probe with driver mtk-pcie-gen3 failed with error -110
```

```
Jan 12 02:12:48 celery kernel: mtdblock: MTD device 'reserved' is NAND, please consider using UBI block devices instead.
Jan 12 02:12:48 celery kernel: mtdblock: MTD device 'bl2' is NAND, please consider using UBI block devices instead.
Jan 12 02:12:48 celery kernel: mtdblock: MTD device 'ubi' is NAND, please consider using UBI block devices instead.
Jan 12 02:12:48 celery kernel: mtdblock: MTD device 'fip' is NAND, please consider using UBI block devices instead.
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

# updating

Take inspiration from https://determinate.systems/posts/hydra-deployment-source-of-truth/
