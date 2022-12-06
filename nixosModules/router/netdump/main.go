package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/netip"
	"strings"
)

type Netdump struct {
	IPv4Cidr                   int    `json:"_ipv4Cidr"`
	IPv6GuaCidr                int    `json:"_ipv6GuaCidr"`
	IPv6UlaCidr                int    `json:"_ipv6UlaCidr"`
	NetworkIPv4                string `json:"_networkIPv4"`
	NetworkIPv4Cidr            string `json:"_networkIPv4Cidr"`
	NetworkIPv4SignificantBits string `json:"_networkIPv4SignificantBits"`
	NetworkGuaCidr             string `json:"_networkGuaCidr"`
	NetworkGuaSignificantBits  string `json:"_networkGuaSignificantBits"`
	NetworkUlaCidr             string `json:"_networkUlaCidr"`
	NetworkUlaSignificantBits  string `json:"_networkUlaSignificantBits"`
}

func getDump(guaPrefixStr, ulaPrefixStr, v4PrefixStr string) (*Netdump, error) {
	guaPrefix, err := netip.ParsePrefix(guaPrefixStr)
	if err != nil {
		return nil, err
	}
	ulaPrefix, err := netip.ParsePrefix(ulaPrefixStr)
	if err != nil {
		return nil, err
	}
	v4Prefix, err := netip.ParsePrefix(v4PrefixStr)
	if err != nil {
		return nil, err
	}

	networkIPv4SignificantBits := []string{}
	{
		v4PrefixAs4 := v4Prefix.Addr().As4()
		for _, b := range v4PrefixAs4[:][0:(v4Prefix.Bits() / 8)] {
			networkIPv4SignificantBits = append(networkIPv4SignificantBits, fmt.Sprintf("%d", b))
		}
	}

	networkGuaPrefix := []string{}
	{
		guaPrefixAs16 := guaPrefix.Addr().As16()
		var tmp string
		for i, b := range guaPrefixAs16[:][0:(guaPrefix.Bits() / 8)] {
			tmp += fmt.Sprintf("%02x", b)
			if i%2 != 0 {
				networkGuaPrefix = append(networkGuaPrefix, tmp)
				tmp = ""
			}
		}
	}

	networkUlaPrefix := []string{}
	{
		ulaPrefixAs16 := ulaPrefix.Addr().As16()
		var tmp string
		for i, b := range ulaPrefixAs16[:][0:(ulaPrefix.Bits() / 8)] {
			tmp += fmt.Sprintf("%02x", b)
			if i%2 != 0 {
				networkUlaPrefix = append(networkUlaPrefix, tmp)
				tmp = ""
			}
		}
	}

	return &Netdump{
		IPv4Cidr:                   v4Prefix.Bits(),
		IPv6GuaCidr:                guaPrefix.Bits(),
		IPv6UlaCidr:                ulaPrefix.Bits(),
		NetworkIPv4:                v4Prefix.Addr().String(),
		NetworkIPv4Cidr:            v4Prefix.String(),
		NetworkGuaCidr:             guaPrefix.String(),
		NetworkUlaCidr:             ulaPrefix.String(),
		NetworkIPv4SignificantBits: strings.Join(networkIPv4SignificantBits, "."),
		NetworkGuaSignificantBits:  strings.Join(networkGuaPrefix, ":"),
		NetworkUlaSignificantBits:  strings.Join(networkUlaPrefix, ":"),
	}, nil
}

func main() {
	guaPrefix := flag.String("gua-prefix", "", "IPv6 GUA network prefix")
	ulaPrefix := flag.String("ula-prefix", "", "IPv6 ULA network prefix")
	v4Prefix := flag.String("v4-prefix", "", "IPv4 network prefix")
	flag.Parse()

	dump, err := getDump(*guaPrefix, *ulaPrefix, *v4Prefix)
	if err != nil {
		log.Fatal(err)
	}
	data, err := json.Marshal(dump)
	if err != nil {
		log.Fatal(err)
	}
	if _, err := fmt.Printf("%s", data); err != nil {
		log.Fatal(err)
	}
}
