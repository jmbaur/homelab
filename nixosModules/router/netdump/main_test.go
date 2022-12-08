package main

import (
	"reflect"
	"testing"
)

func TestGetHostDump(t *testing.T) {
	tt := []struct {
		name      string
		hostID    int
		guaPrefix string
		ulaPrefix string
		v4Prefix  string
		want      *hostDump
	}{
		{
			name:      "first host in network",
			hostID:    1,
			guaPrefix: "2000::/64",
			ulaPrefix: "fc00::/64",
			v4Prefix:  "192.168.0.0/24",
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
			name:      "last host in network",
			hostID:    254,
			guaPrefix: "2000::/64",
			ulaPrefix: "fc00::/64",
			v4Prefix:  "192.168.0.0/24",
			want: &hostDump{
				Ipv4:     "192.168.0.254",
				Ipv4Cidr: "192.168.0.254/24",
				Ipv6: ipv6{
					Gua:     "2000::fe",
					GuaCidr: "2000::fe/64",
					Ula:     "fc00::fe",
					UlaCidr: "fc00::fe/64",
				},
			},
		},
	}

	for _, tc := range tt {
		got, err := getHostDump(tc.hostID, tc.guaPrefix, tc.ulaPrefix, tc.v4Prefix)
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
		name      string
		networkID int
		guaPrefix string
		ulaPrefix string
		v4Prefix  string
		want      *netDump
	}{
		{
			name:      "TODO",
			networkID: 1,
			guaPrefix: "2000::/48",
			ulaPrefix: "fc00::/48",
			v4Prefix:  "192.168.0.0/16",
			want: &netDump{
				IPv4Cidr:                     24,
				IPv6GuaCidr:                  64,
				IPv6UlaCidr:                  64,
				NetworkIPv4:                  "192.168.1.0",
				NetworkIPv4Cidr:              "192.168.1.0/24",
				NetworkIPv4SignificantOctets: "192.168.1",
				NetworkGuaCidr:               "2000:0:0:1::/64",
				NetworkGuaSignificantBits:    "2000:0:0:1",
				NetworkUlaCidr:               "fc00:0:0:1::/64",
				NetworkUlaSignificantBits:    "fc00:0:0:1",
			},
		},
	}

	for _, tc := range tt {
		got, err := getNetworkDump(tc.networkID, tc.guaPrefix, tc.ulaPrefix, tc.v4Prefix)
		if err != nil {
			t.Fatal(err)
		}
		if !reflect.DeepEqual(*got, *tc.want) {
			t.Fatalf("test '%s': got %+v, want %+v", tc.name, got, tc.want)
		}
	}
}
