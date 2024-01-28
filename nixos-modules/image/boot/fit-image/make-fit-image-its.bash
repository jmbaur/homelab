# shellcheck shell=bash

declare description
declare arch
declare linux_kernel
declare initrd
declare kernel_compression
declare bootscript
declare load_address
declare x86_setup_code

devicetree_package=${1:-}
devicetree_name=${2:-}

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

function x86_setup_node() {
	cat <<EOF
		setup {
			description = "Linux setup.bin";
			data = /incbin/("${x86_setup_code}");
			type = "x86_setup";
			arch = "$arch";
			os = "linux";
			compression = "none";
			load = <0x00090000>;
			entry = <0x00090000>;
			hash-1 {
				algo = "crc32";
			};
		};
EOF
}

function x86_setup_configuration() {
	cat <<EOF
		conf-0 {
			description = "Configuration 0";
			setup = "setup";
			kernel = "kernel";
			ramdisk = "ramdisk";
		};
EOF
}

function close_image_node() {
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
if [[ -n $devicetree_package ]]; then
	declare dtb_files
	if [[ -n $devicetree_name ]]; then
		dtb_files="${devicetree_package}/${devicetree_name}"
	else
		mapfile -t dtb_files < <(find -L "$devicetree_package" -type f -name '*.dtb')
	fi

	for index in "${!dtb_files[@]}"; do
		fdt_definition "$index" "${dtb_files[$index]}"
	done
	close_image_node
	configurations
	for index in "${!dtb_files[@]}"; do
		fdt_reference "$index" "${dtb_files[$index]}"
	done
elif [[ -n $x86_setup_code ]]; then
	x86_setup_node
	close_image_node
	configurations
	x86_setup_configuration
fi
bottom
