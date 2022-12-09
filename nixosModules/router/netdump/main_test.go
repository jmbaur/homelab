package main

import (
	"reflect"
	"testing"
)

func TestGetHostDump(t *testing.T) {
	tt := []struct {
		hostID, maxStaticHostID              int
		want                                 *hostDump
		name, guaPrefix, ulaPrefix, v4Prefix string
	}{
		{
			name:            "first host in network",
			hostID:          1,
			maxStaticHostID: (1 << 7) - 1,
			guaPrefix:       "2000::/64",
			ulaPrefix:       "fc00::/64",
			v4Prefix:        "192.168.0.0/24",
			want: &hostDump{
				Ipv4:     "192.168.0.1",
				Ipv4Cidr: "192.168.0.1/24",
				Ipv6: ipv6{
					Gua:     "2000::1",
					GuaCidr: "2000::1/64",
					Ula:     "fc00::1",
					UlaCidr: "fc00::1/64",
				},
			},
		},
		{
			name:            "last host before DHCP pools",
			hostID:          126,
			maxStaticHostID: (1 << 7) - 1,
			guaPrefix:       "2000::/64",
			ulaPrefix:       "fc00::/64",
			v4Prefix:        "192.168.0.0/24",
			want: &hostDump{
				Ipv4:     "192.168.0.126",
				Ipv4Cidr: "192.168.0.126/24",
				Ipv6: ipv6{
					Gua:     "2000::7e",
					GuaCidr: "2000::7e/64",
					Ula:     "fc00::7e",
					UlaCidr: "fc00::7e/64",
				},
			},
		},
		{
			name:            "last host in large network",
			hostID:          (1 << 15) - 1,
			maxStaticHostID: (1 << 15) - 1,
			guaPrefix:       "2000::/64",
			ulaPrefix:       "fc00::/64",
			v4Prefix:        "10.0.0.0/8",
			want: &hostDump{
				Ipv4:     "10.0.127.255",
				Ipv4Cidr: "10.0.127.255/8",
				Ipv6: ipv6{
					Gua:     "2000::7fff",
					GuaCidr: "2000::7fff/64",
					Ula:     "fc00::7fff",
					UlaCidr: "fc00::7fff/64",
				},
			},
		},
	}

	for _, tc := range tt {
		got, err := getHostDump(tc.hostID, tc.maxStaticHostID, tc.guaPrefix, tc.ulaPrefix, tc.v4Prefix)
		if err != nil {
			t.Fatal(err)
		}
		if !reflect.DeepEqual(*got, *tc.want) {
			t.Fatalf("test '%s': got %+v, want %+v", tc.name, got, tc.want)
		}
	}
}

func TestGetNetworkDump(t *testing.T) {
	tt := []struct {
		networkID, maxStaticHostID           int
		want                                 *netDump
		name, guaPrefix, ulaPrefix, v4Prefix string
	}{
		{
			name:            "simple network",
			networkID:       1,
			maxStaticHostID: (1 << 7) - 1,
			guaPrefix:       "2000::/48",
			ulaPrefix:       "fc00::/48",
			v4Prefix:        "192.168.0.0/16",
			want: &netDump{
				IPv4Cidr:                     24,
				IPv6GuaCidr:                  64,
				IPv6UlaCidr:                  64,
				NetworkIPv4:                  "192.168.1.0",
				NetworkIPv4Cidr:              "192.168.1.0/24",
				NetworkIPv4SignificantOctets: "192.168.1",
				Dhcpv4Pool:                   "192.168.1.128/25",
				NetworkGuaCidr:               "2000:0:0:1::/64",
				NetworkUlaCidr:               "fc00:0:0:1::/64",
				UlaDhcpv6Pool:                "fc00:0:0:1:80::/65",
			},
		},
		{
			name:            "larger network",
			networkID:       1,
			maxStaticHostID: (1 << 15) - 1,
			guaPrefix:       "2000::/48",
			ulaPrefix:       "fc00::/48",
			v4Prefix:        "10.0.0.0/8",
			want: &netDump{
				IPv4Cidr:                     16,
				IPv6GuaCidr:                  64,
				IPv6UlaCidr:                  64,
				NetworkIPv4:                  "10.1.0.0",
				NetworkIPv4Cidr:              "10.1.0.0/16",
				NetworkIPv4SignificantOctets: "10.1",
				Dhcpv4Pool:                   "10.1.128.0/17",
				NetworkGuaCidr:               "2000:0:0:1::/64",
				NetworkUlaCidr:               "fc00:0:0:1::/64",
				UlaDhcpv6Pool:                "fc00:0:0:1:8000::/65",
			},
		},
	}

	for _, tc := range tt {
		got, err := getNetworkDump(tc.networkID, tc.maxStaticHostID, tc.guaPrefix, tc.ulaPrefix, tc.v4Prefix)
		if err != nil {
			t.Fatal(err)
		}
		if !reflect.DeepEqual(*got, *tc.want) {
			t.Fatalf("test '%s': got %+v, want %+v", tc.name, got, tc.want)
		}
	}
}
