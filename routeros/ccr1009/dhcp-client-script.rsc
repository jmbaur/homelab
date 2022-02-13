:if ($bound=1) do={
	:log/info "GOT A WAN ADDRESS"

	:local content $"lease-address"

	:delay 5

	:do {
		:local username "TODO"
		:local password "TODO"
		:local hostname "TODO"
		/tool/fetch mode=https http-method=get url="https://$username:$password@ipv4.tunnelbroker.net/nic/update?hostname=$hostname"
	} on-error={
		:log/info "ERROR UPDATING HURRICANE ELECTRIC"
	}

	:do {
		:local zoneid "TODO"
		:local recordid "TODO"
		:local token "TODO"
		:local type "A"
		:local name "TODO"
		:local proxied true
		:local url "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$recordid"
		:local headers "Content-Type: application/json,Authorization: Bearer $token"
		:local data "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"proxied\":$proxied}"
		/tool/fetch mode=https http-method=put http-header-field=$headers http-data=$data url=$url
	} on-error={
		:log/info "ERROR UPDATING CLOUDFLARE"
	}

	:local hurricane [/interface/6to4/find name=sit1]
	/interface/6to4/set $hurricane local-address=$content
} else={
	:log/info "LOST A WAN ADDRESS"
}
