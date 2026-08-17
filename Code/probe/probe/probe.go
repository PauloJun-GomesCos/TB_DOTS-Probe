package probe

import (
	"Code/models"
	"Code/mqttclient"
	"Code/network"
	"Code/probe/capabilities"
	"Code/probe/config"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/shirou/gopsutil/cpu"
	"github.com/shirou/gopsutil/mem"
)

var UpdateChannel chan config.ProbeConfigParams

// Probe represents the state and configuration of a test probe, including its network interfaces, capabilities,
// brokers parameters, monitoring data, and command handlers.
type Probe struct {
	ID              string `json:"-"`
	TypeProbe       []string
	FirmwareVersion string           `json:"-"`
	Network         *network.Network `json:"-"`
	MqttClient      *mqttclient.MQTTClient

	// Probe configuration and supported capabilities
	ProbeConfig      config.ProbeConfigParams
	CapabilitiesInfo []models.Capability `json:"-"`
	ConfigGroups     []models.Group      `json:"-"`
	ConfigParams     []models.Param

	// MQTT broker configuration and currently connected broker
	ConnectedBroker    string            `json:"-"`
	BrokerConfigParams mqttclient.Params `json:"-"`
	BrokerTestParams   mqttclient.Params `json:"-"`

	// Current system resource measurements
	CpuUsage    float64   `json:"-"`
	CpuHistory  []float64 `json:"-"`
	MemoryUsage float64   `json:"-"`
	Temperature float64   `json:"-"`

	// Command executors
	Executors map[string]func(models.MsgCommandRequest, *Probe) `json:"-"`
	StartTime time.Time                                         `json:"-"`
}

// NewProbe creates and initializes a new Probe instance with default values.
func NewProbe() *Probe {
	log.Println("[PROBE] Creating a new probe")

	// Initialize the probe and its network manager.
	probe := &Probe{}
	probe.Network = network.NewNetwork("eth0")

	// Generate a unique probe ID from the MAC address of eth0 using SHA-256.
	mac := probe.Network.Interfaces["eth0"].MAC
	hash := sha256.Sum256([]byte(mac))
	hashHex := fmt.Sprintf("%x", hash)
	probe.ID = "probe-" + hashHex[:6]

	// Initialize the probe metadata and supported capabilities.
	probe.TypeProbe = []string{"ethernet"}
	probe.FirmwareVersion = "0.5.2"
	probe.CapabilitiesInfo = capabilities.GetCapabilitiesList() //List of capabilities completely defined
	probe.ConfigGroups = probe.SetConfigGroupList()             // List of the configuration groups completely defined

	// Initialize the command executors and record the probe startup time.
	probe.Executors = make(map[string]func(models.MsgCommandRequest, *Probe))
	probe.StartTime = time.Now()

	// Load the configuration of the Probe (contain the value of all the configuration parameters).
	probe.ProbeConfig = config.NewProbeConfigParams()

	// Configure the available network interfaces.
	if probe.ProbeConfig.BridgeMode {
		probe.Network.CreateBridge(probe.ProbeConfig.BridgeIP, probe.ProbeConfig.BridgeMask, probe.ProbeConfig.BridgeDHCP, probe.ProbeConfig.BridgeDHCPStart, probe.ProbeConfig.BridgeDHCPStop, probe.ProbeConfig.BridgeDHCPGateway, "br0")
	}

	for _, interfaceName := range probe.Network.GetListOfInterfaces() {
		if interfaceName == "eth0" {
			continue
		} else if interfaceName == "eth1" {
			probe.Network.CreateInterface(probe.ProbeConfig.Eth1IP, probe.ProbeConfig.Eth1Mask, probe.ProbeConfig.Eth1DHCP, probe.ProbeConfig.Eth1DHCPStart, probe.ProbeConfig.Eth1DHCPStop, probe.ProbeConfig.Eth1DHCPGateway, interfaceName)
		} else if interfaceName == "eth2" {
			probe.Network.CreateInterface(probe.ProbeConfig.Eth2IP, probe.ProbeConfig.Eth2Mask, probe.ProbeConfig.Eth2DHCP, probe.ProbeConfig.Eth2DHCPStart, probe.ProbeConfig.Eth2DHCPStop, probe.ProbeConfig.Eth2DHCPGateway, interfaceName)
		} else if interfaceName == "br0" {
			probe.Network.UpdateBridge(probe.ProbeConfig.BridgeIP, probe.ProbeConfig.BridgeMask, probe.ProbeConfig.BridgeDHCP, probe.ProbeConfig.BridgeDHCPStart, probe.ProbeConfig.BridgeDHCPStop, probe.ProbeConfig.BridgeDHCPGateway, "br0")
		}
	}
	return probe
}

// FindBroker searches for a reachable MQTT broker and configures the network interface accordingly.
func (p *Probe) FindBroker() {
	reachable := false

	// Wait until one of the configured brokers becomes reachable.
	for !reachable {
		log.Println("[Probe] Trying to communicate with a broker")
		if IsBrokerReachable(GetBrokerAddress(p.BrokerConfigParams.Broker), 500*time.Millisecond) {
			log.Println("[Probe] Config broker is reachable")
			reachable = true
			p.ConnectedBroker = "ConfigBroker"
		} else if IsBrokerReachable(GetBrokerAddress(p.BrokerTestParams.Broker), 500*time.Millisecond) {
			log.Println("[Probe] Test broker is reachable")
			reachable = true
			p.ConnectedBroker = "TestBroker"
		} else {
			log.Println("[Probe] No broker is reachable actually (retrying in 500ms")
			p.Network.ActivateDHCPClientInterface("eth0")
			time.Sleep(500 * time.Millisecond)
		}
	}

	// Configure the eth0 interface according to the selected broker.
	if p.ConnectedBroker == "ConfigBroker" {
		if p.ProbeConfig.IP != "" {
			p.Network.RemoveIPsFromSubnet("eth0", p.ProbeConfig.Subnet)
			p.Network.SetIP(p.ProbeConfig.IP, p.ProbeConfig.Mask, "eth0")
			p.Network.SetGateway(p.ProbeConfig.Gateway, p.ProbeConfig.IP, p.ProbeConfig.Mask, "eth0")
		}
	} else if p.ConnectedBroker == "TestBroker" {
		if p.ProbeConfig.IP != "" {
			p.Network.ResetInterface("eth0")
			p.Network.DesactivateDHCPClientInterface("eth0")
			p.Network.SetIP(p.ProbeConfig.IP, p.ProbeConfig.Mask, "eth0")
			p.Network.SetGateway(p.ProbeConfig.Gateway, p.ProbeConfig.IP, p.ProbeConfig.Mask, "eth0")
		}
	}
}

// IsBrokerReachable checks whether a TCP connection can be established with the specified broker within the given timeout.
func IsBrokerReachable(address string, timeout time.Duration) bool {
	// Try to establish a TCP connection to the broker
	conn, err := net.DialTimeout("tcp", address, timeout)
	if err != nil {
		return false
	}

	// Close the connection after successfully reaching the broker.
	err = conn.Close()
	if err != nil {
		return false
	}
	return true
}

// GetBrokerAddress extracts the host and port from a broker URL.
func GetBrokerAddress(broker string) string {
	// Parse the broker URL into a URL structure
	u, err := url.Parse(broker)
	if err != nil {
		return ""
	}

	// Return the host and port used to connect to the broker.
	return u.Host
}

// UpdateBrokerTestParams updates the MQTT credentials of the broker of the test environment.
func (p *Probe) UpdateBrokerTestParams() {
	log.Println("[PROBE] Updating broker test params")
	p.BrokerTestParams.Broker = p.ProbeConfig.MQTTURL
	p.BrokerTestParams.ClientId = p.ID
	p.BrokerTestParams.Username = p.ProbeConfig.MQTTUsername
	p.BrokerTestParams.Password = p.ProbeConfig.MQTTPassword
	p.BrokerTestParams.Timeout = p.BrokerConfigParams.Timeout
}

// SetConfigGroupList defines the list of Configuration groups with all the metadata that the coordinator needs.
func (p *Probe) SetConfigGroupList() []models.Group {
	log.Println("[PROBE] Setting config group")
	ConfigGroups := []models.Group{
		{Key: "network", Label: "Network", Icon: "lan"},
		{Key: "mqtt", Label: "MQTT credentials", Icon: "hub"},
		{Key: "bridge", Label: "Bridge", Icon: "device_hub", VisibleIf: &models.VisibleCondition{Key: "bridge_mode", Value: true}},
		{Key: "eth1", Label: "Interface eth1", Icon: "settings_ethernet", VisibleIf: &models.VisibleCondition{Key: "bridge_mode", Value: false}},
		{Key: "eth2", Label: "Interface eth2", Icon: "settings_ethernet", VisibleIf: &models.VisibleCondition{Key: "bridge_mode", Value: false}},
	}
	return ConfigGroups
}

// SetConfigParamsList defines the list of Configuration parameters with all the metadata that the coordinator needs.
func (p *Probe) SetConfigParamsList() []models.Param {
	log.Println("[PROBE] Setting config params")
	Config := []models.Param{
		{Key: "name", Label: "Name", Type: "string", Value: p.ProbeConfig.Name},
		{Key: "status_interval_s", Label: "Status interval", Type: "number", Value: p.ProbeConfig.StatusInterval, Min: 1, Max: 3600, Unit: "s"},
		{Key: "enable", Label: "Enabled", Type: "boolean", Value: p.ProbeConfig.Enabled},
		{Key: "bridge_mode", Label: "Bridge activated", Type: "boolean", Value: p.ProbeConfig.BridgeMode},

		{Key: "ip", Label: "IP address", Type: "string", Value: p.ProbeConfig.IP, Group: "network"},
		{Key: "mask", Label: "Subnet mask", Type: "string", Value: p.ProbeConfig.Mask, Group: "network"},
		{Key: "gateway", Label: "Gateway", Type: "string", Value: p.ProbeConfig.Gateway, Group: "network"},
		{Key: "subnet", Label: "Subnet", Type: "string", Value: p.ProbeConfig.Subnet, Group: "network"},

		{Key: "mqtt_url", Label: "MQTT server", Type: "string", Value: p.ProbeConfig.MQTTURL, Group: "mqtt"},
		{Key: "mqtt_username", Label: "MQTT username", Type: "string", Value: p.ProbeConfig.MQTTUsername, Group: "mqtt"},
		{Key: "mqtt_password", Label: "MQTT password", Type: "string", Value: p.ProbeConfig.MQTTPassword, Group: "mqtt"},

		{Key: "bridge_ip", Label: "IP address", Type: "string", Value: p.ProbeConfig.BridgeIP, Group: "bridge"},
		{Key: "bridge_mask", Label: "Subnet mask", Type: "string", Value: p.ProbeConfig.BridgeMask, Group: "bridge"},
		{Key: "bridge_dhcp_activated", Label: "DHCP activated", Type: "bool", Value: p.ProbeConfig.BridgeDHCP, Group: "bridge"},
		{Key: "bridge_dhcp_start", Label: "DHCP start address", Type: "string", Value: p.ProbeConfig.BridgeDHCPStart, Group: "bridge"},
		{Key: "bridge_dhcp_stop", Label: "DHCP stop address", Type: "string", Value: p.ProbeConfig.BridgeDHCPStop, Group: "bridge"},
		{Key: "bridge_dhcp_gateway", Label: "DHCP gateway", Type: "string", Value: p.ProbeConfig.BridgeDHCPGateway, Group: "bridge"},

		{Key: "eth1_ip", Label: "IP address", Type: "string", Value: p.ProbeConfig.Eth1IP, Group: "eth1"},
		{Key: "eth1_mask", Label: "Subnet mask", Type: "string", Value: p.ProbeConfig.Eth1Mask, Group: "eth1"},
		{Key: "eth1_dhcp_activated", Label: "DHCP activated", Type: "bool", Value: p.ProbeConfig.Eth1DHCP, Group: "eth1"},
		{Key: "eth1_dhcp_start", Label: "DHCP start address", Type: "string", Value: p.ProbeConfig.Eth1DHCPStart, Group: "eth1"},
		{Key: "eth1_dhcp_stop", Label: "DHCP stop address", Type: "string", Value: p.ProbeConfig.Eth1DHCPStop, Group: "eth1"},
		{Key: "eth1_dhcp_gateway", Label: "DHCP gateway", Type: "string", Value: p.ProbeConfig.Eth1DHCPGateway, Group: "eth1"},

		{Key: "eth2_ip", Label: "IP address", Type: "string", Value: p.ProbeConfig.Eth2IP, Group: "eth2"},
		{Key: "eth2_mask", Label: "Subnet mask", Type: "string", Value: p.ProbeConfig.Eth2Mask, Group: "eth2"},
		{Key: "eth2_dhcp_activated", Label: "DHCP activated", Type: "bool", Value: p.ProbeConfig.Eth2DHCP, Group: "eth2"},
		{Key: "eth2_dhcp_start", Label: "DHCP start address", Type: "string", Value: p.ProbeConfig.Eth2DHCPStart, Group: "eth2"},
		{Key: "eth2_dhcp_stop", Label: "DHCP stop address", Type: "string", Value: p.ProbeConfig.Eth2DHCPStop, Group: "eth2"},
		{Key: "eth2_dhcp_gateway", Label: "DHCP gateway", Type: "string", Value: p.ProbeConfig.Eth2DHCPGateway, Group: "eth2"},
	}
	return Config
}

// GetCpuUsagePercent returns the average CPU usage based on the latest measurements as a percentage.
func (p *Probe) GetCpuUsagePercent() float64 {
	percent, err := cpu.Percent(0, false)
	if err != nil {
		log.Println("[PROBE] Error getting cpu usage percent :", err)
		return -1
	}

	// Add the latest CPU usage measurement to the history.
	p.CpuHistory = append(p.CpuHistory, percent[0])

	// Keep only the two most recent measurements.
	if len(p.CpuHistory) > 2 {
		p.CpuHistory = p.CpuHistory[1:]
	}

	// Calculate the average CPU usage.
	var sum float64
	for _, v := range p.CpuHistory {
		sum += v
	}

	return sum / float64(len(p.CpuHistory))
}

// GetMemoryUsagePercent returns the current system memory usage as a percentage.
func (p *Probe) GetMemoryUsagePercent() float64 {
	memory, err := mem.VirtualMemory()
	if err != nil {
		log.Println("[PROBE] Error getting memory usage percent :", err)
		return 0
	}

	return memory.UsedPercent
}

// GetTemperature returns the current CPU temperature in degrees Celsius.
func (p *Probe) GetTemperature() float64 {
	data, err := os.ReadFile("/sys/class/thermal/thermal_zone0/temp")
	if err != nil {
		log.Println("[PROBE] Error reading the temperature :", err)
		return 0
	}

	// Parse the temperature value and convert it from millidegrees to degrees Celsius.
	v, err := strconv.ParseFloat(strings.TrimSpace(string(data)), 64)
	if err != nil {
		log.Println("[PROBE] Error parsing temperature :", err)
		return 0
	}
	return v / 1000
}

// SendMsgAnnounce send the announcement message by publishing it on probes/announce.
func (p *Probe) SendMsgAnnounce(requestID *string) {
	log.Println("[PROBE] Sending announce message")
	p.Network.UpdateNetworkInfos()

	// Create the announcement message.
	response := models.MsgAnnounce{
		ProbeID:         p.ID,
		RequestID:       requestID,
		Type:            p.TypeProbe,
		FirmwareVersion: p.FirmwareVersion,

		Capabilities: p.CapabilitiesInfo,      // List of capabilities with all the metadata for the coordinator
		ConfigGroups: p.ConfigGroups,          // List of configuration groups with all the metadata for the coordinator
		ConfigParams: p.SetConfigParamsList(), // List of configuration parameters with all the metadata for the coordinator

		Network:   p.Network.ToNetworkInfo(),
		Timestamp: time.Now().UnixMilli(),
	}

	resultPayload, err := json.Marshal(response)
	if err != nil {
		log.Println("[PROBE] Error marshaling the announce payload :", err)
		return
	}

	// Publish the announcement message.
	log.Println("[PROBE] Publishing the announcement message in the topic 'probes/announce'")
	err = p.MqttClient.Publish("probes/announce", string(resultPayload))
	if err != nil {
		log.Println("[PROBE] Error publishing the announcement message :", err)
		return
	}
}

// SendMsgStatus send the status message by publishing it on probes/{probe_id}/status.
func (p *Probe) SendMsgStatus() {
	p.CpuUsage = p.GetCpuUsagePercent()
	p.MemoryUsage = p.GetMemoryUsagePercent()
	p.Temperature = p.GetTemperature()

	log.Println("[PROBE] Sending status message")
	// Create the status message.
	status := models.MsgStatus{
		Name:          p.ProbeConfig.Name,
		State:         "",
		Uptime:        int(time.Since(p.StartTime).Seconds()),
		CpuPercent:    p.CpuUsage,
		MemoryPercent: p.MemoryUsage,
		Temperature:   p.Temperature,
		Timestamp:     time.Now().UnixMilli(),
	}

	if p.ProbeConfig.Enabled {
		status.State = "online"
	} else {
		status.State = "disabled"
	}

	payload, err := json.Marshal(status)
	if err != nil {
		log.Println("[PROBE] Error marshaling the status payload :", err)
		return
	}

	// Publish the status message.
	log.Println("[PROBE] Publishing the status message in the topic 'probes/{probe_id}/status}'")
	err = p.MqttClient.Publish("probes/"+p.ID+"/status", string(payload))
	if err != nil {
		log.Println("[PROBE] Error publishing the status message :", err)
		return
	}
}

// SendSuccessResponse send the success response by publishing it on probes/{probe_id}/response.
func (p *Probe) SendSuccessResponse(ID string, result any) {
	log.Println("[PROBE] Sending success response")
	// Create the success response.
	response := models.MsgResponse{
		ID:        ID,
		Status:    "success",
		Error:     models.ErrorInfo{Code: 0, Message: ""},
		Result:    result,
		Timestamp: time.Now().UnixMilli(),
	}

	responsePayload, err := json.Marshal(response)
	if err != nil {
		log.Println("[PROBE] Error marshaling the response payload :", err)
		return
	}

	// Publish the success response.
	log.Println("[PROBE] Publishing the success response in the topic 'probes/{probe_id}/response'")
	err = p.MqttClient.Publish("probes/"+p.ID+"/response", string(responsePayload))
	if err != nil {
		log.Println("[PROBE] Error publishing the success response :", err)
		return
	}
}

// SendProcessingResponse send the processing response by publishing it on probes/{probe_id}/response.
func (p *Probe) SendProcessingResponse(ID string) {
	log.Println("[PROBE] Sending processing response")
	// Create the processing response.
	response := models.MsgResponse{
		ID:        ID,
		Status:    "processing",
		Error:     models.ErrorInfo{Code: 0, Message: ""},
		Result:    models.ResultEmpty{},
		Timestamp: time.Now().UnixMilli(),
	}

	responsePayload, err := json.Marshal(response)
	if err != nil {
		log.Println("[PROBE] Error marshaling the response payload :", err)
		return
	}

	// Publish the processing response.
	log.Println("[PROBE] Publishing the processing response in the topic 'probes/{probe_id}/response'")
	err = p.MqttClient.Publish("probes/"+p.ID+"/response", string(responsePayload))
	if err != nil {
		log.Println("[PROBE] Error publishing the processing response :", err)
		return
	}
}

// SendErrorResponse send the error response by publishing it on probes/{probe_id}/response.
func (p *Probe) SendErrorResponse(ID string, Error models.ErrorInfo) {
	log.Println("[PROBE] Sending error message")
	// Create the error response.
	response := models.MsgResponse{
		ID:        ID,
		Status:    "error",
		Error:     Error,
		Result:    models.ResultEmpty{},
		Timestamp: time.Now().UnixMilli(),
	}

	responsePayload, err := json.Marshal(response)
	if err != nil {
		log.Println("[PROBE] Error marshaling the response payload :", err)
		return
	}

	// Publish the error response.
	log.Println("[PROBE] Publishing the error response in the topic 'probes/{probe_id}/response'")
	err = p.MqttClient.Publish("probes/"+p.ID+"/response", string(responsePayload))
	if err != nil {
		log.Println("[PROBE] Error publishing the error response :", err)
		return
	}
}
