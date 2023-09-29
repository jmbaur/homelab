# BananaPi R3 Dip Switches

| Jumper Setting | SW1  | SW2  | SW5  | SW6  |
| -------------- | ---- | ---- | ---- | ---- |
| SPIM-NoR       | Low  | Low  | Low  | X    |
| SPIM-Nand      | High | Low  | High | X    |
| eMMC           | Low  | High | High | Low  |
| SD card        | High | High | X    | High |

# openwrt default environment

```console
MT7986> printenv
boot_default=if env exists flag_recover ; then else run bootcmd ; fi ; run boot_recovery ; setenv replacevol 1 ; run boot_tftp_forever
boot_first=if button reset ; then led $bootled_rec on ; run boot_tftp_recovery ; setenv flag_recover 1 ; run boot_default ; fi ; bootmenu
boot_production=run boot_update_conf ; led $bootled_pwr on ; run ubi_read_production && bootm $loadaddr#$bootconf ; led $bootled_pwr off
boot_recovery=run boot_update_conf ; led $bootled_rec on ; run ubi_read_recovery && bootm $loadaddr#$bootconf ; led $bootled_rec off
boot_tftp=run boot_update_conf ; tftpboot $loadaddr $bootfile && bootm $loadaddr#$bootconf
boot_tftp_forever=led $bootled_rec on ; while true ; do run boot_tftp_recovery ; sleep 1 ; done
boot_tftp_production=run boot_update_conf ; tftpboot $loadaddr $bootfile_upg && env exists replacevol && iminfo $loadaddr && run ubi_write_production ; if env exists noboot ; then else bootm $loadaddr#$bootconf ; fi
boot_tftp_recovery=run boot_update_conf ; tftpboot $loadaddr $bootfile && env exists replacevol && iminfo $loadaddr && run ubi_write_recovery ; if env exists noboot ; then else bootm $loadaddr#$bootconf ; fi
boot_tftp_write_bl2=tftpboot $loadaddr $bootfile_bl2 && run mtd_write_bl2
boot_tftp_write_fip=tftpboot $loadaddr $bootfile_fip && run mtd_write_fip && run reset_factory
boot_ubi=run boot_update_conf ; run boot_production ; run boot_recovery
boot_update_conf=if mmc partconf 0 ; then setenv bootconf $bootconf_base#$bootconf_nand#$bootconf_emmc ; else setenv bootconf  $bootconf_base#$bootconf_nand#$bootconf_sd ; fi
bootargs=root=/dev/ubiblock0_2p1
bootcmd=if pstore check ; then run boot_recovery ; else run boot_ubi ; fi
bootconf=config-mt7986a-bananapi-bpi-r3
bootconf_base=config-mt7986a-bananapi-bpi-r3
bootconf_emmc=mt7986a-bananapi-bpi-r3-emmc
bootconf_nand=mt7986a-bananapi-bpi-r3-nand
bootconf_nor=mt7986a-bananapi-bpi-r3-nor
bootconf_sd=mt7986a-bananapi-bpi-r3-sd
bootdelay=3
bootfile=openwrt-mediatek-filogic-bananapi_bpi-r3-initramfs-recovery.itb
bootfile_bl2=openwrt-mediatek-filogic-bananapi_bpi-r3-snand-preloader.bin
bootfile_fip=openwrt-mediatek-filogic-bananapi_bpi-r3-snand-bl31-uboot.fip
bootfile_upg=openwrt-mediatek-filogic-bananapi_bpi-r3-squashfs-sysupgrade.itb
bootled_pwr=green:status
bootled_rec=blue:status
bootmenu_0=Run default boot command.=run boot_default
bootmenu_1=Boot system via TFTP.=run boot_tftp ; run bootmenu_confirm_return
bootmenu_10=Reset all settings to factory defaults.=run reset_factory ; reset
bootmenu_2=Boot production system from NAND.=run boot_production ; run bootmenu_confirm_return
bootmenu_3=Boot recovery system from NAND.=run boot_recovery ; run bootmenu_confirm_return
bootmenu_4=Load production system via TFTP then write to NAND.=setenv noboot 1 ; setenv replacevol 1 ; run boot_tftp_production ; setenv noboot ; setenv replacevol ; run bootmenu_confirm_return
bootmenu_5=Load recovery system via TFTP then write to NAND.=setenv noboot 1 ; setenv replacevol 1 ; run boot_tftp_recovery ; setenv noboot ; setenv replacevol ; run bootmenu_confirm_return
bootmenu_6=Load BL31+U-Boot FIP via TFTP then write to NAND.=run boot_tftp_write_fip ; run bootmenu_confirm_return
bootmenu_7=Load BL2 preloader via TFTP then write to NAND.=run boot_tftp_write_bl2 ; run bootmenu_confirm_return
bootmenu_8=Install bootloader, recovery and production to eMMC.=if mmc partconf 0 ; then run emmc_init ; else echo "eMMC not detected" ; fi ; run bootmenu_confirm_return
bootmenu_9=Reboot.=reset
bootmenu_confirm_return=askenv - Press ENTER to return to menu ; bootmenu 60
bootmenu_default=0
bootmenu_delay=3
bootmenu_title=      ( ( ( OpenWrt ) ) )  [SPI-NAND]       U-Boot 2023.07.02-OpenWrt-r24039-4c83b6a4f8 (Sep 25 2023 - 18:18:52 +0000)
console=earlycon=uart8250,mmio32,0x11002000 console=ttyS0
emmc_init=mmc dev 0 && mmc bootbus 0 0 0 0 && run emmc_init_bl && run emmc_init_openwrt ; env default bootcmd ; saveenv ; saveenv
emmc_init_bl=run ubi_read_emmc_install && setenv fileaddr $loadaddr && run emmc_write_bl2 && setexpr fileaddr $loadaddr + 0x100000 && run emmc_write_fip && setexpr fileaddr $loadaddr + 0x500000 && run emmc_write_hdr
emmc_init_openwrt=run ubi_read_recovery && iminfo $loadaddr && run emmc_write_recovery ; run ubi_read_production && iminfo $loadaddr && run emmc_write_production
emmc_write_bl2=mmc partconf 0 1 1 1 && mmc erase 0x0 0x400 && mmc write $fileaddr 0x0 0x400 ; mmc partconf 0 1 1 0
emmc_write_fip=mmc erase 0x3400 0x2000 && mmc write $fileaddr 0x3400 0x2000 && mmc erase 0x2000 0x800
emmc_write_hdr=mmc erase 0x0 0x40 && mmc write $fileaddr 0x0 0x40
emmc_write_production=part start mmc 0 $part_default part_addr && part size mmc 0 $part_default part_size && run mmc_write_vol
emmc_write_recovery=part start mmc 0 $part_recovery part_addr && part size mmc 0 $part_recovery part_size && run mmc_write_vol
ethaddr=36:e6:40:55:58:ad
ipaddr=192.168.1.1
loadaddr=0x46000000
mmc_write_vol=imszb $loadaddr image_size && test 0x$image_size -le 0x$part_size && mmc erase 0x$part_addr 0x$image_size && mmc write $loadaddr 0x$part_addr 0x$image_size
mtd_write_bl2=mtd erase bl2 && mtd write bl2 $loadaddr
mtd_write_fip=mtd erase fip && mtd write fip $loadaddr
part_default=production
part_recovery=recovery
reset_factory=ubi part ubi ; mw $loadaddr 0x0 0x800 ; ubi write $loadaddr ubootenv 0x800 ; ubi write $loadaddr ubootenv2 0x800
serverip=192.168.1.254
ubi_create_env=ubi check ubootenv || ubi create ubootenv 0x100000 dynamic 0 ; ubi check ubootenv2 || ubi create ubootenv2 0x100000 dynamic 1
ubi_format=ubi detach ; mtd erase ubi && ubi part ubi ; reset
ubi_prepare_rootfs=if ubi check rootfs_data ; then else if env exists rootfs_data_max ; then ubi create rootfs_data $rootfs_data_max dynamic || ubi create rootfs_data - dynamic ; else ubi create rootfs_data - dynamic ; fi ; fi
ubi_read_emmc_install=ubi check emmc_install && ubi read $loadaddr emmc_install
ubi_read_production=ubi read $loadaddr fit && iminfo $loadaddr && run ubi_prepare_rootfs
ubi_read_recovery=ubi check recovery && ubi read $loadaddr recovery
ubi_remove_rootfs=ubi check rootfs_data && ubi remove rootfs_data
ubi_write_production=ubi check fit && ubi remove fit ; run ubi_remove_rootfs ; ubi create fit $filesize dynamic 2 && ubi write $loadaddr fit $filesize
ubi_write_recovery=ubi check recovery && ubi remove recovery ; run ubi_remove_rootfs ; ubi create recovery $filesize dynamic 3 && ubi write $loadaddr recovery $filesize
ver=U-Boot 2023.07.02-OpenWrt-r24039-4c83b6a4f8 (Sep 25 2023 - 18:18:52 +0000)

Environment size: 6584/126971 bytes
```
