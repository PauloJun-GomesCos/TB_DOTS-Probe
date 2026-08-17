package network

import (
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/vishvananda/netlink"
)

// Network represents the network information of the probe, including IP address, MAC address,
// and network interface name.
type Network struct {
	// Interfaces contains the network information indexed by interface name.
	Interfaces map[string]Interface `json:"-"`

	// DhcpServers contains the list of active DHCP servers indexed by interface name.
	DhcpServers map[string]*DHCPServer `json:"-"`
}

// Interface represents the network information associated with an interface.
type Interface struct {
	IPs []string `json:"ip"`  // IPs contains the list of IPv4 addresses assigned to the interface.
	MAC string   `json:"mac"` // MAC contains the MAC address of the interface.
}

// DHCPServer represents a running DHCP server associated with an interface.
type DHCPServer struct {
	interfaceName string    // Name of the interface where the DHCP server is running.
	cmd           *exec.Cmd // Command used to start and manage the DHCP server process.
}

// NewNetwork creates and initializes a new Network instance. The function waits until the specified interface
// is available and has received an IP address before returning the initialized network object.
func NewNetwork(interfaceName string) *Network {
	log.Println("[NETWORK] Creating a new network")

	network := Network{}                            // Create a new network instance.
	network.Interfaces = make(map[string]Interface) // Initialize the interface map.

	// Stop all DHCP servers to ensure that eth1 and eth2 start without.
	network.StopAllDHCPServers()

	for {
		// Check if the required interface is available.
		for _, i := range network.GetListOfInterfaces() {
			if i == interfaceName {
				// Retrieve the IPv4 addresses assigned to the interface.
				addrs := network.GetListOfAddr(interfaceName)

				// Wait until the interface has an IP address.
				if len(addrs) > 0 {
					// Store the initial network information.
					network.Interfaces[interfaceName] = Interface{
						IPs: network.GetListOfAddr(interfaceName),
						MAC: network.GetMAC(interfaceName),
					}
					// Initialize the DHCP server map.
					network.DhcpServers = make(map[string]*DHCPServer)

					return &network
				}
			}
		}
		// Wait a seconde before checking again.
		time.Sleep(1 * time.Second)
		network.ActivateDHCPClientInterface("eth0")
	}
}

// UpdateNetworkInfos updates the internal network information by retrieving the current IPv4 addresses and MAC address
// of each network interface.
func (network *Network) UpdateNetworkInfos() {
	log.Println("[NETWORK] Updating network infos")
	network.Interfaces = make(map[string]Interface)
	for _, i := range network.GetListOfInterfaces() {
		network.Interfaces[i] = Interface{
			IPs: network.GetListOfAddr(i),
			MAC: network.GetMAC(i),
		}
	}
}

// ToNetworkInfo returns the current network information for all network interfaces in a suitable format for the
// other components (msgAnnounce). The returned structure maps each interface name to its associated IPv4 addresses
// and MAC address.
func (network *Network) ToNetworkInfo() map[string]Interface {
	result := make(map[string]Interface)
	for name, iface := range network.Interfaces {
		result[name] = Interface{
			IPs: iface.IPs,
			MAC: iface.MAC,
		}
	}
	return result
}

// DesactivateDHCPClientInterface stops the dhcpcd client on the specified interface by executing the command in the
// host namespaces using nsenter.
func (network *Network) DesactivateDHCPClientInterface(interfaceName string) {
	log.Println("[NETWORK] Stopping DHCP client on", interfaceName)
	cmd := exec.Command(
		"nsenter",
		"--target", "1",
		"--mount",
		"--uts",
		"--ipc",
		"--net",
		"--pid",
		"dhcpcd",
		"-x",
		interfaceName,
	)
	err := cmd.Start()
	if err != nil {
		log.Println("[NETWORK] Error stopping DHCP client on", interfaceName)
	}
	log.Println("[NETWORK] DHCP client stopped on", interfaceName)
}

// ActivateDHCPClientInterface starts the dhcpcd client on the specified interface by executing the command in the
// host namespaces using nsenter.
func (network *Network) ActivateDHCPClientInterface(interfaceName string) {
	log.Println("[NETWORK] Starting DHCP client on", interfaceName)
	cmd := exec.Command(
		"nsenter",
		"--target", "1",
		"--mount",
		"--uts",
		"--ipc",
		"--net",
		"--pid",
		"dhcpcd",
		interfaceName,
	)
	err := cmd.Start()
	if err != nil {
		log.Println("[NETWORK] Error starting DHCP client on", interfaceName)
	}
	log.Println("[NETWORK] DHCP client started on", interfaceName)
}

// ResetInterface resets the specified network interface by removing all IP addresses assigned to it.
func (network *Network) ResetInterface(interfaceName string) {
	log.Println("[NETWORK] Resetting interface", interfaceName)
	for _, ip := range network.GetListOfAddr(interfaceName) {
		ipOnly := strings.Split(ip, "/")[0]
		maskOnly, err := strconv.Atoi(strings.Split(ip, "/")[1])
		if err != nil {
			log.Println("[NETWORK] Error converting prefix to int:", err)
			continue
		}
		mask, _ := PrefixToMask(maskOnly)

		network.RemoveIP(ipOnly, mask, interfaceName)
	}
}

// GetListOfAddr returns the list of IPv4 addresses assigned to the specified network interface. Each address
// is returned in CIDR notation (e.g. 192.168.1.10/24).
func (network *Network) GetListOfAddr(interfaceName string) []string {
	log.Println("[NETWORK] Getting list of addresses on interface", interfaceName)
	interfaceLink, err := netlink.LinkByName(interfaceName)
	if err != nil {
		log.Println("[NETWORK] Error getting interface", interfaceName)
		return nil
	}

	addrs, err := netlink.AddrList(interfaceLink, 0)
	if err != nil {
		log.Println("[NETWORK] Error getting addresses on interface", interfaceName)
		return nil
	}

	var addrsIP []string

	for _, addr := range addrs {
		if addr.IP.To4() == nil {
			continue
		}
		addrsIP = append(addrsIP, addr.IPNet.String())
	}

	log.Println("[NETWORK] Addresses found on interface", interfaceName, ":", addrsIP)
	return addrsIP
}

// GetListOfInterfaces returns the list of available network interfaces, If eth1 and eth2 belongs to a bridge, the
// bridge name is returned instead of the physical interfaces.
func (network *Network) GetListOfInterfaces() []string {
	log.Println("[NETWORK] Getting list of interfaces")
	links, err := netlink.LinkList()
	if err != nil {
		log.Println("[NETWORK] Error getting list of interfaces:", err)
		return nil
	}

	interfaces := []string{}

	// Keep track of already added interfaces to avoid duplicates.
	seen := make(map[string]bool)

	for _, l := range links {
		attrs := l.Attrs()

		// Only consider the Ethernet interfaces used by the probe.
		if attrs.Name != "eth0" && attrs.Name != "eth1" && attrs.Name != "eth2" {
			continue
		}

		// Check whether the interface is attached to a bridge.
		if attrs.MasterIndex != 0 {
			master, err := netlink.LinkByIndex(attrs.MasterIndex)
			if err == nil && master.Type() == "bridge" {
				name := master.Attrs().Name
				// Add the bridge only if it has not already been added.
				if !seen[name] {
					interfaces = append(interfaces, name)
					seen[name] = true
				}
				continue
			}
		}

		// If the interface does not belong to a bridge, add the physical interface directly.
		if !seen[attrs.Name] {
			interfaces = append(interfaces, attrs.Name)
			seen[attrs.Name] = true
		}
	}

	log.Println("[NETWORK-GetListOfInterfaces] Interfaces found:", interfaces)
	return interfaces
}

// CheckInterfaceExist checks whether the specified network interface exists in the list of available network interfaces.
func (network *Network) CheckInterfaceExist(interfaceName string) bool {
	log.Println("[NETWORK] Checking if interface", interfaceName, "exists")
	listInterfaces := network.GetListOfInterfaces()

	for _, iface := range listInterfaces {
		if interfaceName == iface {
			log.Println("[NETWORK] Interface", interfaceName, "exist")
			return true
		}
	}
	log.Println("[NETWORK] Interface", interfaceName, "doesn't exist")
	return false
}

// GetMAC returns the MAC address of the specified network interface.
func (network *Network) GetMAC(interfaceName string) string {
	log.Println("[NETWORK] Getting MAC address of interface", interfaceName)
	link, err := netlink.LinkByName(interfaceName)
	if err != nil {
		log.Println("[NETWORK] Error finding interface:", err)
		return ""
	}

	if link.Attrs().HardwareAddr == nil {
		log.Println("[NETWORK] Interface", interfaceName, "has no MAC address")
		return ""
	}

	log.Println("[NETWORK] Interface", interfaceName, "MAC address:", link.Attrs().HardwareAddr.String())
	return link.Attrs().HardwareAddr.String()
}

// MaskValid check whether the provided string is a valid IPv4 subnet mask. The function verifies that the mask is a
// valid IPv4 address and that it represents a contiguous subnet mask (e.g. 255.255.255.0).
func MaskValid(mask string) bool {
	// Parse the string as an IP address.
	ip := net.ParseIP(mask).To4()
	if ip == nil {
		return false
	}

	// Determine the prefix length and verify that the mask is contiguous.
	// If the mask is not contiguous, Size() returns ones == -1.
	ones, bits := net.IPMask(ip).Size()

	// A valid IPv4 mask has 32 bits and a contiguous prefix.
	if bits == 32 && ones != -1 {
		return true
	}
	return false
}

// MaskToPrefix converts an IPv4 subnet mask in dotted decimal notation into its corresponding CIDR prefix length.
func MaskToPrefix(mask string) (int, error) {
	// Parse the string as an IP address.
	ip := net.ParseIP(mask).To4()
	if ip == nil {
		return 0, fmt.Errorf("invalid mask: %s", mask)
	}

	// Determine if the prefix length correspond to the subnet mask.
	ones, bits := net.IPMask(ip).Size()
	if bits != 32 {
		return 0, fmt.Errorf("invalid IPv4 mask")
	}

	// Return the CIDR prefix
	return ones, nil
}

// PrefixToMask converts an IPv4 CIDR prefix length into its corresponding subnet mask in dotted decimal notation.
func PrefixToMask(prefix int) (string, error) {
	// Ensure the prefix length is within the valid IPv4 range.
	if prefix < 0 || prefix > 32 {
		return "", fmt.Errorf("invalid prefix: %d", prefix)
	}

	// Create the subnet mask from the CIDR prefix length.
	mask := net.CIDRMask(prefix, 32)

	// Return the subnet mask in dotted decimal notation.
	return net.IP(mask).String(), nil
}

// SetIP assigns the specified IPv4 address and subnet mask to the given network interface.
func (network *Network) SetIP(ip string, mask string, interfaceName string) {
	log.Println("[NETWORK] Setting IP", ip, " with mask", mask, "on interface", interfaceName)

	link, err := netlink.LinkByName(interfaceName)
	if err != nil {
		log.Println("[NETWORK] Error finding interface:", err)
		return
	}

	prefix, err := MaskToPrefix(mask)
	if err != nil {
		log.Println("[NETWORK] Error converting mask:", err)
		return
	}

	addr, err := netlink.ParseAddr(fmt.Sprintf("%s/%d", ip, prefix))
	if err != nil {
		log.Println("[NETWORK] Error parsing IP:", err)
		return
	}

	err = netlink.AddrAdd(link, addr)
	if err != nil {
		log.Println("[NETWORK] Error adding IP address:", err)
		return
	}

	log.Println("[NETWORK] IP", ip, "with mask", mask, "set on interface", interfaceName)
}

// RemoveIP removes the specified IPv4 address and subnet mask from the given network interface.
func (network *Network) RemoveIP(ip string, mask string, interfaceName string) {
	log.Println("[NETWORK] Removing IP", ip, "from interface", interfaceName)

	link, err := netlink.LinkByName(interfaceName)
	if err != nil {
		log.Println("[NETWORK] Error finding interface:", err)
		return
	}

	prefix, err := MaskToPrefix(mask)
	if err != nil {
		log.Println("[Network] Error converting mask:", err)
		return
	}

	addr, err := netlink.ParseAddr(fmt.Sprintf("%s/%d", ip, prefix))
	if err != nil {
		log.Println("[Network] Error parsing IP:", err)
		return
	}

	err = netlink.AddrDel(link, addr)
	if err != nil {
		log.Println("[Network] Error removing IP:", err)
		return
	}

	log.Println("[NETWORK] IP", ip, "removed from interface", interfaceName)
}

// RemoveIPsFromSubnet removes all IPv4 addresses assigned to the specified network interface that belong to the given subnet.
func (network *Network) RemoveIPsFromSubnet(interfaceName string, subnet string) {
	log.Println("[NETWORK] Removing IPs from the subnet", subnet, "on interface", interfaceName)

	link, err := netlink.LinkByName(interfaceName)
	if err != nil {
		log.Println("[NETWORK] Error finding interface:", err)
		return
	}

	_, ipNet, err := net.ParseCIDR(subnet)
	if err != nil {
		log.Println("[NETWORK] Invalid subnet", subnet, ":", err)
		return
	}

	addresses, err := netlink.AddrList(link, 0)
	if err != nil {
		log.Println("[NETWORK] Error getting addresses on interface", interfaceName)
		return
	}

	for _, addr := range addresses {
		ip := addr.IP
		if ipNet.Contains(ip) {
			log.Println("[NETWORK] Removing IP", ip, "from interface", interfaceName)

			err := netlink.AddrDel(link, &addr)
			if err != nil {
				log.Println("[Network] Error removing IP:", err)
				return
			}
		}
	}
}

// SetGateway configures a default gateway for the specified network interface using the provided gateway
// address and source network configuration.
func (network *Network) SetGateway(gateway string, sourceIP string, sourceMask string, interfaceName string) {
	log.Println("[NETWORK] Setting gateway", gateway, "on interface", interfaceName)

	link, err := netlink.LinkByName(interfaceName)
	if err != nil {
		log.Println("[NETWORK] Error finding interface:", err)
		return
	}

	route := &netlink.Route{
		LinkIndex: link.Attrs().Index,
		Gw:        net.ParseIP(gateway),
		Src:       net.ParseIP(sourceIP),
		Priority:  2000,
	}

	err = netlink.RouteReplace(route)
	if err != nil {
		log.Println("[NETWORK] Error replacing route:", err)
		return
	}

	log.Println("[NETWORK] Gateway", gateway, "set on interface", interfaceName)
}

// CreateInterface configures a network interface with the specified IPv4 settings and, optionally, enables and
// configures a DHCP server on that interface.
func (network *Network) CreateInterface(interfaceIP string, interfaceMask string, dhcpActivated bool, dhcpStartIP string, dhcpStopIP string, dhcpGatewayIP string, interfaceName string) {
	log.Println("[NETWORK] Creating interface on", interfaceName)

	network.ResetInterface(interfaceName)

	if interfaceIP == "" {
		network.ActivateDHCPClientInterface(interfaceName)
	} else {
		network.DesactivateDHCPClientInterface(interfaceName)
		log.Println("[NETWORK] Setting IP", interfaceIP, "on the interface", interfaceName)
		network.SetIP(interfaceIP, interfaceMask, interfaceName)
	}

	if dhcpActivated {
		network.SetDHCPServer(dhcpStartIP, dhcpStopIP, dhcpGatewayIP, interfaceName)
	} else {
		network.StopDHCPServer(interfaceName)
	}
}

// CreateBridge creates and configures a network bridge with the specified IPv4 settings and, optionally, enables
// and configures a DHCP server on the bridge.
func (network *Network) CreateBridge(bridgeIP string, bridgeMask string, dhcpActivated bool, dhcpStartIP string, dhcpStopIP string, dhcpGatewayIP string, bridgeName string) {
	log.Println("[NETWORK] Creating a bridge named", bridgeName, "that contains eth1 and eth2")

	network.StopAllDHCPServers()
	network.ResetInterface("eth1")
	network.DesactivateDHCPClientInterface("eth1")
	network.ResetInterface("eth2")
	network.DesactivateDHCPClientInterface("eth2")

	BridgeAttrs := netlink.NewLinkAttrs()
	BridgeAttrs.Name = bridgeName

	bridge := &netlink.Bridge{LinkAttrs: BridgeAttrs}
	err := netlink.LinkAdd(bridge)
	if err != nil {
		log.Println("[NETWORK] Error creating bridge:", err)
		return
	}

	err = netlink.LinkSetUp(bridge)
	if err != nil {
		log.Println("[NETWORK] Error setting up bridge:", err)
		return
	}

	eth1, _ := netlink.LinkByName("eth1")
	eth2, _ := netlink.LinkByName("eth2")

	err = netlink.LinkSetMaster(eth1, bridge)
	if err != nil {
		log.Println("[NETWORK] Error adding interface eth1 to bridge:", err)
		return
	}
	err = netlink.LinkSetMaster(eth2, bridge)
	if err != nil {
		log.Println("[NETWORK] Error adding interface eth2 to bridge:", err)
		return
	}

	err = netlink.LinkSetUp(eth1)
	if err != nil {
		log.Println("[NETWORK] Error setting up eth1 to bridge:", err)
	}
	err = netlink.LinkSetUp(eth2)
	if err != nil {
		log.Println("[NETWORK] Error setting up eth2 to bridge:", err)
	}

	if bridgeIP == "" {
		network.ActivateDHCPClientInterface(bridgeName)
	} else {
		network.DesactivateDHCPClientInterface(bridgeName)
		log.Println("[NETWORK] Setting IP", bridgeIP, "on the bridge", bridgeName)
		network.SetIP(bridgeIP, bridgeMask, bridgeName)
	}

	if dhcpActivated {
		network.SetDHCPServer(dhcpStartIP, dhcpStopIP, dhcpGatewayIP, bridgeName)
	}
}

// DeleteBridge deletes the specified network bridge, restores the original configuration of its member interfaces,
// and reapplies their respective IP, gateway, and DHCP settings.
func (network *Network) DeleteBridge(bridgeName string, interfaces []string,
	ipEth1 string, maskEth1 string, dhcpActivatedEth1 bool, dhcpStartIPEth1 string, dhcpStopIPEth1 string, dhcpGatewayIPEth1 string,
	ipEth2 string, maskEth2 string, dhcpActivatedEth2 bool, dhcpStartIPEth2 string, dhcpStopIPEth2 string, dhcpGatewayIPEth2 string) {
	log.Println("[NETWORK] Deleting the bridge named", bridgeName, "and restoring interfaces eth1 and eth2")
	network.StopAllDHCPServers()

	bridge, _ := netlink.LinkByName(bridgeName)

	for _, name := range interfaces {
		iface, err := netlink.LinkByName(name)
		if err != nil {
			log.Println("[NETWORK] Error getting interface", name, "from the bridge:", err)
			continue
		}

		// remove master (bridge)
		err = netlink.LinkSetNoMaster(iface)
		if err != nil {
			log.Println("[NETWORK] Error removing interface", name, "from the bridge:", err)
		}

		// bring interface up
		err = netlink.LinkSetUp(iface)
		if err != nil {
			log.Println("[NETWORK] Error setting interface", name, "up:", err)
		}
	}

	err := netlink.LinkDel(bridge)
	if err != nil {
		log.Println("[NETWORK] Error deleting bridge:", err)
	}

	network.CreateInterface(ipEth1, maskEth1, dhcpActivatedEth1, dhcpStartIPEth1, dhcpStopIPEth1, dhcpGatewayIPEth1, "eth1")
	network.CreateInterface(ipEth2, maskEth2, dhcpActivatedEth2, dhcpStartIPEth2, dhcpStopIPEth2, dhcpGatewayIPEth2, "eth2")
}

// UpdateBridge updates the IPv4 and DHCP server configuration of an existing network bridge.
func (network *Network) UpdateBridge(bridgeIP string, bridgeMask string, dhcpActivated bool, dhcpStartIP string, dhcpStopIP string, dhcpGatewayIP string, bridgeName string) {
	log.Println("[NETWORK] Updating bridge", bridgeName)
	network.StopAllDHCPServers()
	network.ResetInterface(bridgeName)
	if bridgeIP == "" {
		network.ActivateDHCPClientInterface(bridgeName)
	} else {
		network.DesactivateDHCPClientInterface(bridgeName)
		log.Println("[NETWORK] Setting IP", bridgeIP, "on the bridge", bridgeName)
		network.SetIP(bridgeIP, bridgeMask, bridgeName)
	}

	if dhcpActivated {
		network.SetDHCPServer(dhcpStartIP, dhcpStopIP, dhcpGatewayIP, bridgeName)
	}
}

// SetDHCPServer configures and starts a DHCP server on the specified network interface using the provided address
// range and gateway. It uses dnsmasq for the dhcp server.
func (network *Network) SetDHCPServer(ipStart string, ipStop string, ipGateway string, interfaceName string) {
	cmd := exec.Command(
		"dnsmasq",
		"--keep-in-foreground",
		"--interface="+interfaceName,
		"--except-interface=lo",
		"--bind-interfaces",
		fmt.Sprintf("--dhcp-range=%s,%s,12h", ipStart, ipStop),
		fmt.Sprintf("--dhcp-option=3,%s", ipGateway),
		fmt.Sprintf("--dhcp-option=6,%s", ipGateway),
	)
	log.Println("[NETWORK] Setting DHCP server", cmd)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	log.Println("[NETWORK] Starting the DCHP server (dnsmasq) on interface", interfaceName)
	if err := cmd.Start(); err != nil {
		log.Println("[NETWORK] Error starting the DCHP server:", err)
		return
	}

	network.DhcpServers[interfaceName] = &DHCPServer{
		cmd:           cmd,
		interfaceName: interfaceName,
	}
	log.Println("[NETWORK] DCHP server (dnsmasq) started on interface", interfaceName)
}

// StopDHCPServer stops the DHCP servers running on a specific network interfaces.
func (network *Network) StopDHCPServer(interfaceName string) {
	log.Println("[NETWORK] Stop DHCP server on interface", interfaceName)
	dhcpServer, exists := network.DhcpServers[interfaceName]
	if !exists {
		log.Println("[NETWORK] No DHCP server found on interface", interfaceName)
		return
	}

	if dhcpServer != nil && dhcpServer.cmd != nil && dhcpServer.cmd.Process != nil {
		log.Println("[NETWORK] Stopping DHCP server (dnsmasq) on interface", interfaceName)

		_ = dhcpServer.cmd.Process.Kill()

		err := dhcpServer.cmd.Wait()
		if err != nil {
			log.Println("[NETWORK] Error stopping DHCP server:", err)
		}
	}

	// remove only this DHCP server from the map
	delete(network.DhcpServers, interfaceName)
}

// StopAllDHCPServers stops all the DHCP servers running on the network interfaces.
func (network *Network) StopAllDHCPServers() {
	log.Println("[NETWORK] Stop all DHCP servers")
	for interfaceName, cmd := range network.DhcpServers {
		if cmd != nil && cmd.cmd.Process != nil {
			log.Println("[NETWORK] Stoping the DCHP server (dnsmasq) on interface", interfaceName)
			_ = cmd.cmd.Process.Kill()
			err := cmd.cmd.Wait()
			if err != nil {
				log.Println("[NETWORK] Error stopping the DCHP server:", err)
			}
		}
	}

	// reset map
	network.DhcpServers = make(map[string]*DHCPServer)
}
