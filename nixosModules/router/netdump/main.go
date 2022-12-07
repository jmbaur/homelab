// netdump will dump generated IP addresses for hosts or networks. For hosts,
// it chooses IPs within a subnet. For networks, it chooses subnets within
// larger subnets.
package main

import (
	"encoding/binary"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/netip"
	"strings"
)

var (
	errNetworkTooSmall  = errors.New("ipv6 network too small")
	errInvalidNetworkID = errors.New("invalid network ID")
	errIDTooLarge       = errors.New("ID too large")
)

type ipv6 struct {
	Gua     string `json:"gua"`
	GuaCidr string `json:"guaCidr"`
	Ula     string `json:"ula"`
	UlaCidr string `json:"ulaCidr"`
}

type hostDump struct {
	Ipv4     string `json:"_ipv4"`
	Ipv4Cidr string `json:"_ipv4Cidr"`
	Ipv6     ipv6   `json:"_ipv6"`
}

type netDump struct {
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

func getHostDump(hostID int, guaPrefixStr, ulaPrefixStr, v4PrefixStr string) (*hostDump, error) {
	if hostID <= 0 {
		return nil, errors.New("invalid host ID")
	}

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

	// 2 reserved IPs per network:
	// - network address
	// - broadcast multicast address
	availableIPv4Addresses := 1<<(32-v4Prefix.Bits()) - 2
	if hostID > availableIPv4Addresses {
		return nil, errIDTooLarge
	}

	bs := make([]byte, 4)
	binary.BigEndian.PutUint32(bs, uint32(hostID))

	guaArray := guaPrefix.Addr().As16()
	guaArray[12] += bs[0]
	guaArray[13] += bs[1]
	guaArray[14] += bs[2]
	guaArray[15] += bs[3]

	ulaArray := ulaPrefix.Addr().As16()
	ulaArray[12] += bs[0]
	ulaArray[13] += bs[1]
	ulaArray[14] += bs[2]
	ulaArray[15] += bs[3]

	v4Array := v4Prefix.Addr().As4()
	v4Array[0] += bs[0]
	v4Array[1] += bs[1]
	v4Array[2] += bs[2]
	v4Array[3] += bs[3]

	ipv4 := netip.AddrFrom4(v4Array)
	gua := netip.AddrFrom16(guaArray)
	ula := netip.AddrFrom16(ulaArray)
	return &hostDump{
		Ipv4:     ipv4.String(),
		Ipv4Cidr: netip.PrefixFrom(ipv4, v4Prefix.Bits()).String(),
		Ipv6: ipv6{
			Gua:     gua.String(),
			GuaCidr: netip.PrefixFrom(gua, guaPrefix.Bits()).String(),
			Ula:     ula.String(),
			UlaCidr: netip.PrefixFrom(ula, ulaPrefix.Bits()).String(),
		},
	}, nil
}

func getNetworkDump(networkID int, guaPrefixStr, ulaPrefixStr, v4PrefixStr string) (*netDump, error) {
	if networkID <= 0 {
		return nil, errInvalidNetworkID
	}

	guaPrefix, err := netip.ParsePrefix(guaPrefixStr)
	if err != nil {
		return nil, err
	}
	guaPrefix = guaPrefix.Masked()
	if guaPrefix.Bits() >= 64 {
		return nil, errNetworkTooSmall
	}
	if networkID >= 1<<(128-64-guaPrefix.Bits()) {
		return nil, errIDTooLarge
	}
	ulaPrefix, err := netip.ParsePrefix(ulaPrefixStr)
	if err != nil {
		return nil, err
	}
	ulaPrefix = ulaPrefix.Masked()
	if ulaPrefix.Bits() >= 64 {
		return nil, errNetworkTooSmall
	}
	if networkID >= 1<<(128-64-ulaPrefix.Bits()) {
		return nil, errIDTooLarge
	}
	v4Prefix, err := netip.ParsePrefix(v4PrefixStr)
	if err != nil {
		return nil, err
	}
	v4Prefix = v4Prefix.Masked()
	if v4Prefix.Bits() >= 24 {
		return nil, errNetworkTooSmall
	}
	if networkID >= 1<<(32-8-v4Prefix.Bits()) {
		return nil, errIDTooLarge
	}

	arrSize := int(float64((32 - 8 - v4Prefix.Bits()) / 8))
	bs := make([]byte, arrSize)
	switch arrSize {
	case 1:
		bs = []byte{uint8(networkID)}
	case 2:
		binary.BigEndian.PutUint16(bs, uint16(networkID))
	case 3:
		binary.BigEndian.PutUint32(bs, uint32(networkID))
	case 4:
		binary.BigEndian.PutUint64(bs, uint64(networkID))
	}

	guaArray := guaPrefix.Addr().As16()
	for i := 0; i < arrSize; i++ {
		guaArray[7-i] += bs[i]
	}

	ulaArray := ulaPrefix.Addr().As16()
	for i := 0; i < arrSize; i++ {
		ulaArray[7-i] += bs[i]
	}

	v4Array := v4Prefix.Addr().As4()
	for i := 0; i < arrSize; i++ {
		v4Array[2-i] += bs[i]
	}

	networkGuaPrefix := netip.PrefixFrom(netip.AddrFrom16(guaArray), 64)
	networkUlaPrefix := netip.PrefixFrom(netip.AddrFrom16(ulaArray), 64)
	networkV4Prefix := netip.PrefixFrom(netip.AddrFrom4(v4Array), 24)

	networkIPv4SignificantBits := []string{}
	{
		for _, b := range networkV4Prefix.Addr().AsSlice()[0:(networkV4Prefix.Bits() / 8)] {
			networkIPv4SignificantBits = append(networkIPv4SignificantBits, fmt.Sprintf("%d", b))
		}
	}

	networkGuaSignificantBits := []string{}
	{
		var tmp string
		for i, b := range networkGuaPrefix.Addr().AsSlice()[0:(networkGuaPrefix.Bits() / 8)] {
			tmp += fmt.Sprintf("%02x", b)
			if i%2 != 0 {
				networkGuaSignificantBits = append(networkGuaSignificantBits, tmp)
				tmp = ""
			}
		}
	}

	networkUlaSignificantBits := []string{}
	{
		var tmp string
		for i, b := range networkUlaPrefix.Addr().AsSlice()[0:(networkUlaPrefix.Bits() / 8)] {
			tmp += fmt.Sprintf("%02x", b)
			if i%2 != 0 {
				networkUlaSignificantBits = append(networkUlaSignificantBits, tmp)
				tmp = ""
			}
		}
	}

	return &netDump{
		IPv4Cidr:                   networkV4Prefix.Bits(),
		IPv6GuaCidr:                networkGuaPrefix.Bits(),
		IPv6UlaCidr:                networkUlaPrefix.Bits(),
		NetworkIPv4:                networkV4Prefix.Addr().String(),
		NetworkIPv4Cidr:            networkV4Prefix.String(),
		NetworkGuaCidr:             networkGuaPrefix.String(),
		NetworkUlaCidr:             networkUlaPrefix.String(),
		NetworkIPv4SignificantBits: strings.Join(networkIPv4SignificantBits, "."),
		NetworkGuaSignificantBits:  strings.Join(networkGuaSignificantBits, ":"),
		NetworkUlaSignificantBits:  strings.Join(networkUlaSignificantBits, ":"),
	}, nil
}

func main() {
	doHostDump := flag.Bool("host", false, "Do host dump")
	doNetworkDump := flag.Bool("network", false, "Do host dump")
	id := flag.Int("id", -1, "The ID of the network")
	guaPrefix := flag.String("gua-prefix", "", "IPv6 GUA network prefix")
	ulaPrefix := flag.String("ula-prefix", "", "IPv6 ULA network prefix")
	v4Prefix := flag.String("v4-prefix", "", "IPv4 network prefix")
	flag.Parse()

	if *doHostDump == *doNetworkDump {
		log.Fatal("must choose either -host or -network for info dump")
	}

	var (
		err  error
		dump any
	)
	if *doHostDump {
		dump, err = getHostDump(*id, *guaPrefix, *ulaPrefix, *v4Prefix)
	} else {
		dump, err = getNetworkDump(*id, *guaPrefix, *ulaPrefix, *v4Prefix)
	}
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
