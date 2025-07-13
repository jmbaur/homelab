# updating firmware

Build `config.system.build.firmware`, place the output files onto some storage medium, and plug that into the board.

```console
uboot> load usb 0:1 $loadaddr bl2.img
uboot> mtd erase bl2
uboot> mtd write bl2 $loadaddr
uboot> load usb 0:1 $loadaddr fip.bin
uboot> mtd erase fip
uboot> mtd write fip $loadaddr
uboot> load usb 0:1 $loadaddr ubi.img
uboot> mtd erase ubi
uboot> mtd write ubi $loadaddr
```

# dip switches

SW1-A and SW1-B are for bootstrap selection, SW1-C and SW1-D are for system connection.

| Device   | SW1-A | SW1-B | SW1-C | SW1-D
| ---------| ------| ------| ------| -----
| SPI-NOR  | Low   | Low   | Low   | X
| SPI-NAND | High  | Low   | High  | X
| eMMC     | Low   | High  | X     | Low
| SD       | High  | High  | X     | High

For our configuration, we boot firmware from SPI-NAND and OS from eMMC, so we set our dipswitches to High,Low,High,Low.
