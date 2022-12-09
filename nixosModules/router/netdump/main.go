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
	"math"
	"net/netip"
	"strings"
)

const (
	ipv6NetworkSize = 64
)

var (
	errIDTooLarge              = errors.New("network/host ID too large")
	errInvalidNetworkID        = errors.New("invalid network ID")
	errMaxStaticHostIDTooLarge = errors.New("max static host ID too large")
	errNetworkTooSmall         = errors.New("ipv6 network too small")

	makeIPv4AddressOverlay = mustMakeIPAddressOverlay(4)
	makeIPv6AddressOverlay = mustMakeIPAddressOverlay(16)
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
	IPv4Cidr                     int    `json:"_ipv4Cidr"`
	IPv6GuaCidr                  int    `json:"_ipv6GuaCidr"`
	IPv6UlaCidr                  int    `json:"_ipv6UlaCidr"`
	NetworkIPv4                  string `json:"_networkIPv4"`
	NetworkIPv4Cidr              string `json:"_networkIPv4Cidr"`
	NetworkIPv4SignificantOctets string `json:"_networkIPv4SignificantOctets"`
	Dhcpv4Pool                   string `json:"_dhcpv4Pool"`
	NetworkGuaCidr               string `json:"_networkGuaCidr"`
	NetworkUlaCidr               string `json:"_networkUlaCidr"`
	UlaDhcpv6Pool                string `json:"_dhcpv6Pool"`
}

func mustMakeIPAddressOverlay(size int) func(num uint64, prefix int) ([]byte, error) {
	if size != 4 && size != 16 {
		log.Panicf("invalid byte slice size %d", size)
	}

	return func(num uint64, prefix int) ([]byte, error) {
		bs := make([]byte, size)

		if num >= (1<<prefix)-1 {
			return bs, errIDTooLarge
		}

		var start int
		if size == 16 {
			// IPv6 byte layout requires `start` to be the closest multiple
			// of 2.
			start = int(math.Ceil(float64(prefix)/16)-1) * 2
		} else {
			start = int(math.Ceil(float64(prefix)/8)) - 1
		}

		tmp := []byte{} // len(tmp) is either 2 or 4
		switch {
		case num > (1<<32)-1:
			tmp = binary.BigEndian.AppendUint64(tmp, num)
		case num > (1<<16)-1:
			// pad with 0 so length is multiple of two
			if size == 16 {
				tmp = append(tmp, 0)
			}
			tmp = binary.BigEndian.AppendUint32(tmp, uint32(num))
		case num > (1<<8)-1:
			tmp = binary.BigEndian.AppendUint16(tmp, uint16(num))
		default:
			// pad with 0 so length is multiple of two
			if size == 16 {
				tmp = append(tmp, 0)
			}
			tmp = append(tmp, byte(num))
		}

		for i := 0; i < len(tmp); i++ {
			bs[start+i] = tmp[i]
		}

		return bs, nil
	}
}

func getHostDump(hostID, maxStaticHostID int, guaPrefixStr, ulaPrefixStr, v4PrefixStr string) (*hostDump, error) {
	if hostID <= 0 || hostID > maxStaticHostID {
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

	// For dual-stack, the host ID needs to fit within the 32 bits of IPv4, so
	// we hardcode the byte indexes for the IPv6 address slice.
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

func getNetworkDump(networkID, maxStaticHostID int, guaPrefixStr, ulaPrefixStr, v4PrefixStr string) (*netDump, error) {
	if networkID <= 0 {
		return nil, errInvalidNetworkID
	}

	guaPrefix, err := netip.ParsePrefix(guaPrefixStr)
	if err != nil {
		return nil, err
	}
	guaPrefix = guaPrefix.Masked()
	if guaPrefix.Bits() >= ipv6NetworkSize {
		return nil, errNetworkTooSmall
	}
	if networkID >= 1<<(128-ipv6NetworkSize-guaPrefix.Bits()) {
		return nil, errIDTooLarge
	}
	ulaPrefix, err := netip.ParsePrefix(ulaPrefixStr)
	if err != nil {
		return nil, err
	}
	ulaPrefix = ulaPrefix.Masked()
	if ulaPrefix.Bits() >= ipv6NetworkSize {
		return nil, errNetworkTooSmall
	}
	if networkID >= 1<<(128-ipv6NetworkSize-ulaPrefix.Bits()) {
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

	nextPowerOf8 := int(math.Floor(float64(v4Prefix.Bits())/8))*8 + 8
	networkV4Overlay, err := makeIPv4AddressOverlay(uint64(networkID), nextPowerOf8)
	if err != nil {
		return nil, err
	}

	v4Array := v4Prefix.Addr().As4()
	for i := 0; i < len(networkV4Overlay); i++ {
		v4Array[i] += networkV4Overlay[i]
	}

	networkV6Overlay, err := makeIPv6AddressOverlay(uint64(networkID), ipv6NetworkSize)
	if err != nil {
		return nil, err
	}

	guaArray := guaPrefix.Addr().As16()
	{
		for i := 0; i < len(networkV6Overlay); i++ {
			guaArray[i] += networkV6Overlay[i]
		}
	}

	ulaArray := ulaPrefix.Addr().As16()
	{
		for i := 0; i < len(networkV6Overlay); i++ {
			ulaArray[i] += networkV6Overlay[i]
		}
	}

	networkGuaPrefix := netip.PrefixFrom(netip.AddrFrom16(guaArray), ipv6NetworkSize)
	networkUlaPrefix := netip.PrefixFrom(netip.AddrFrom16(ulaArray), ipv6NetworkSize)
	networkV4Prefix := netip.PrefixFrom(netip.AddrFrom4(v4Array), nextPowerOf8)

	var networkIPv4SignificantOctets string
	{
		octets := []string{}
		for _, b := range networkV4Prefix.Addr().AsSlice()[0:(int(math.Ceil(float64(networkV4Prefix.Bits()) / 8)))] {
			octets = append(octets, fmt.Sprintf("%d", b))
		}
		networkIPv4SignificantOctets = strings.Join(octets, ".")
	}

	var dhcpv4Pool string
	var cidrBitDifference int
	var firstDhcpHostID int
	{
		var dhcpCidr int
		halfHostID := 1 << (32 - networkV4Prefix.Bits()) / 2
		for i := 32 - networkV4Prefix.Bits() - 1; i >= 0; i-- {
			maybeStartHostID := int(math.Pow(2, float64(i)))
			if maxStaticHostID < maybeStartHostID {
				if halfHostID < maybeStartHostID {
					firstDhcpHostID = halfHostID
					dhcpCidr = networkV4Prefix.Bits() + 1
				} else {
					firstDhcpHostID = maybeStartHostID
					dhcpCidr = 32 - i
				}
				break
			}
		}

		dhcpv4AddressOverlay, err := makeIPv4AddressOverlay(uint64(firstDhcpHostID), dhcpCidr)
		if err != nil {
			return nil, err
		}

		if dhcpCidr < networkV4Prefix.Bits() {
			return nil, errMaxStaticHostIDTooLarge
		}

		cidrBitDifference = dhcpCidr - networkV4Prefix.Bits()
		v4Array := networkV4Prefix.Addr().As4()
		for i := 0; i < len(dhcpv4AddressOverlay); i++ {
			v4Array[i] += dhcpv4AddressOverlay[i]
		}

		dhcpv4Pool = netip.PrefixFrom(netip.AddrFrom4(v4Array), dhcpCidr).String()
	}

	var ulaDhcpv6Pool string
	{
		dhcpCidr := networkUlaPrefix.Bits() + cidrBitDifference
		dhcpv6AddressOverlay, err := makeIPv6AddressOverlay(uint64(firstDhcpHostID), dhcpCidr)
		if err != nil {
			return nil, err
		}

		v6Array := networkUlaPrefix.Addr().As16()
		for i := 0; i < len(dhcpv6AddressOverlay); i++ {
			v6Array[i] += dhcpv6AddressOverlay[i]
		}

		ulaDhcpv6Pool = netip.PrefixFrom(netip.AddrFrom16(v6Array), dhcpCidr).String()
	}

	return &netDump{
		IPv4Cidr:                     networkV4Prefix.Bits(),
		IPv6GuaCidr:                  networkGuaPrefix.Bits(),
		IPv6UlaCidr:                  networkUlaPrefix.Bits(),
		NetworkIPv4:                  networkV4Prefix.Addr().String(),
		NetworkIPv4Cidr:              networkV4Prefix.String(),
		NetworkIPv4SignificantOctets: networkIPv4SignificantOctets,
		Dhcpv4Pool:                   dhcpv4Pool,
		NetworkGuaCidr:               networkGuaPrefix.String(),
		NetworkUlaCidr:               networkUlaPrefix.String(),
		UlaDhcpv6Pool:                ulaDhcpv6Pool,
	}, nil
}

func main() {
	doHostDump := flag.Bool("host", false, "Do host dump")
	doNetworkDump := flag.Bool("network", false, "Do host dump")
	id := flag.Int("id", -1, "The ID of the network")
	maxStaticHostID := flag.Int("max-static-host-id", (1<<7)-1, "Maximum ID of static hosts in the network") // half of a /24 ipv4 network
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
		dump, err = getHostDump(*id, *maxStaticHostID, *guaPrefix, *ulaPrefix, *v4Prefix)
	} else {
		dump, err = getNetworkDump(*id, *maxStaticHostID, *guaPrefix, *ulaPrefix, *v4Prefix)
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
