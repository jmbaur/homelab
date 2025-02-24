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

| Device           | SW1 #1 | SW1 #2 | SW1 #3 | SW1 #4
| ---------------- | ------ | ------ | ------ | ------
| SPI-NOR          | OFF    | OFF    | OFF    | X
| SPI-NAND         | ON     | OFF    | ON     | X
| eMMC             | OFF    | ON     | X      | OFF
| SD               | ON     | ON     | X      | ON
