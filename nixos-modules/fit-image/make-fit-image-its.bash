# shellcheck shell=bash

declare description
declare arch
declare linux_kernel
declare initrd

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
		kernel {
			description = "linux kernel";
			data = /incbin/("$linux_kernel");
			type = "kernel";
			arch = "$arch";
			os = "linux";
			compression = "lzma";
			load = <00000000>;
			entry = <00000000>;
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
			load = <00000000>;
			entry = <00000000>;
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
	cat <<EOF
		conf-${idx} {
			kernel = "kernel";
			fdt = "fdt-${idx}";
			ramdisk = "ramdisk";
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
