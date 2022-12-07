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
				Ipv4: "192.168.0.1",
				Ipv6: ipv6{
					Gua: "2000::1",
					Ula: "fc00::1",
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
				Ipv4: "192.168.0.254",
				Ipv6: ipv6{
					Gua: "2000::fe",
					Ula: "fc00::fe",
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
	t.Skip("TODO")
}
