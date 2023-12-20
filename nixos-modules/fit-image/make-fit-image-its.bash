# shellcheck shell=bash

declare description
declare arch
declare linux_kernel
declare initrd
declare kernel_compression
declare bootscript
declare load_address

dtbs=$1
mapfile -t dtb_files < <(find -L "$dtbs" -type f -name '*.dtb')

function top() {
	echo
	cat <<EOF
/dts-v1/;

/ {
	description = "$description";
	#address-cells = <1>;

	images {
		bootscript {
			description = "bootscript";
			data = /incbin/("$bootscript");
			type = "script";
			compression = "none";
			hash-1 {
				algo = "crc32";
			};
		};
		kernel {
			description = "linux kernel";
			data = /incbin/("$linux_kernel");
			type = "kernel";
			arch = "$arch";
			os = "linux";
			compression = "$kernel_compression";
			load = <$load_address>;
			entry = <$load_address>;
			hash-1 {
				algo = "crc32";
			};
		};
		ramdisk {
			description = "initrd";
			data = /incbin/("$initrd");
			type = "ramdisk";
			arch = "$arch";
			os = "linux";
			compression = "none";
			hash-1 {
				algo = "crc32";
			};
		};
EOF
}

function fdt_definition() {
	local idx=$1
	local filepath=$2
	cat <<EOF
		fdt-${idx} {
			description = "$(basename "$filepath")";
			data = /incbin/("${filepath}");
			type = "flat_dt";
			arch = "$arch";
			compression = "none";
			hash-1 {
				algo = "crc32";
			};
		};
EOF
}

function finish_fdt_definition() {
	cat <<EOF
	};
EOF
}

function configurations() {
	cat <<EOF
	configurations {
		default = "conf-0";
EOF
}

fdt_reference() {
	local idx=$1
	local filepath=$2
	cat <<EOF
		conf-${idx} {
			description = "Configuration for $(basename "$filepath")";
			kernel = "kernel";
			ramdisk = "ramdisk";
			fdt = "fdt-${idx}";
		};
EOF
}

function bottom() {
	cat <<EOF
	};
};
EOF
}

# print fit image ITS content
top
for index in "${!dtb_files[@]}"; do
	fdt_definition "$index" "${dtb_files[$index]}"
done
finish_fdt_definition
configurations
for index in "${!dtb_files[@]}"; do
	fdt_reference "$index" "${dtb_files[$index]}"
done
bottom
