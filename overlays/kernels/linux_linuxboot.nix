{ lib
, stdenv
, linuxKernel
, u-root
, writeText
, runCommand
, ubootTools
, xz
, dtbFile
, ...
}:
let
  initramfs = u-root.overrideAttrs (_: {
    postBuild = ''
      GOROOT="$(go env GOROOT)" ./go/bin/u-root \
        -uroot-source go/src/$goPackagePath \
        -uinitcmd=systemboot \
        core ./cmds/boot/{systemboot,localboot,fbnetboot}
    '';
    installPhase = ''
      mkdir -p $out
      cp /tmp/initramfs.*.cpio $out/initramfs.cpio
    '';
  });
  kernel = (linuxKernel.manualConfig {
    inherit lib stdenv;
    inherit (linuxKernel.kernels.linux_6_0) src version modDirVersion kernelPatches extraMakeFlags;
    configfile =
      if
        stdenv.hostPlatform.system == "x86_64-linux" then ./linuxboot-x86_64.config
      else if
        stdenv.hostPlatform.system == "aarch64-linux" then ./linuxboot-aarch64.config
      else
        throw "unsupported architecture for linuxboot";
  }).overrideAttrs (old: {
    preConfigure = "cp ${initramfs}/initramfs.cpio /tmp/initramfs.cpio";
    passthru = old.passthru // { inherit initramfs; };
  });
  fitimageITS = writeText "linuxboot-fitimage.its" ''
    /*
     * Simple U-Boot uImage source file containing a single kernel and FDT blob
     */

    /dts-v1/;

    / {
    	description = "Simple image with single Linux kernel and FDT blob";
    	#address-cells = <1>;

    	images {
    		kernel {
    			description = "Vanilla Linux kernel";
    			data = /incbin/("Image.lzma");
    			type = "kernel";
    			arch = "arm64";
    			os = "linux";
    			compression = "lzma";
    			load = <0x80000>;
    			entry = <0x80000>;
    			hash-1 {
    				algo = "crc32";
    			};
    		};
    		fdt-1 {
    			description = "Flattened Device Tree blob";
    			data = /incbin/("target.dtb");
    			type = "flat_dt";
    			arch = "arm64";
    			compression = "none";
    			hash-1 {
    				algo = "crc32";
    			};
    		};
    		ramdisk-1 {
    			description = "Compressed Initramfs";
    			data = /incbin/("initramfs.cpio.xz");
    			type = "ramdisk";
    			arch = "arm64";
    			os = "linux";
    			compression = "none";
    			load = <00000000>;
    			entry = <00000000>;
    			hash-1 {
    				algo = "sha1";
    			};
    		};
    	};

    	configurations {
    		default = "conf-1";
    		conf-1 {
    			description = "Boot Linux kernel with FDT blob";
    			kernel = "kernel";
    			fdt = "fdt-1";
    			ramdisk = "ramdisk-1";
    		};
    	};
    };
  '';
  fitimage = runCommand "linuxboot-fitimage" { } ''
    mkdir -p $out
    ${xz}/bin/lzma --threads 0 <${kernel}/Image >Image.lzma
    cp $(find ${kernel}/dtbs -type f -name ${dtbFile}) target.dtb
    xz --check=crc32 --lzma2=dict=512KiB <${initramfs} >initramfs.cpio.xz
    ${ubootTools}/bin/mkimage -f ${fitimageITS} $out/uImage
  '';
in
if
  stdenv.hostPlatform.system == "x86_64-linux" then kernel
else if
  stdenv.hostPlatform.system == "aarch64-linux" then fitimage
else
  throw "unsupported architecture for linuxboot"
