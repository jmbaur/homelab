# shellcheck shell=bash

# NOTE: A limitation of this script is that some of the OUIs returned from the below URL are in a range syntax (e.g.

declare -r url="https://www.wireshark.org/download/automated/data/manuf.gz"

cache_dir=${XDG_CACHE_HOME:-${HOME:-$(mktemp -d)}/.cache}

manuf_location="${cache_dir}/manuf.gz"

(
	content_length=$(curl --head --output /dev/null --write-out '%header{content-length}' --silent "$url")

	if [[ $(du --bytes "$manuf_location" 2>/dev/null | cut -d$'\t' -f1) != "$content_length" ]]; then
		curl --output "$manuf_location" --location --silent "$url"
	fi
) || true

if [[ ! -f $manuf_location ]]; then
	echo "Vendor OUI data file not found."
	exit 1
fi

declare -A vendors

while IFS=' ' read -r oui description; do
	vendors[$oui]=$description
done < <(gzip --decompress <"$manuf_location" | grep '^[^#]' | awk '{$2 = ""; print $0;}')

while IFS=' ' read -r _addr _dev_literal dev maybe_status mac _foo _bar; do
	if [[ $maybe_status == "FAILED" ]]; then continue; fi

	# shellcheck disable=SC2001
	oui=$(sed 's,\([0-9A-F]\{2\}:[0-9A-F]\{2\}:[0-9A-F]\{2\}\).*,\1,' <<<"${mac^^}")
	vendor=${vendors[$oui]:-}
	if [[ -z $vendor ]]; then
		vendor="Unknown Vendor"
	fi

	echo "${mac^^} -> $vendor via $dev"
done < <(
	# TODO(jared): Use `-json` output from iproute2
	ip -6 neighbour show
)
