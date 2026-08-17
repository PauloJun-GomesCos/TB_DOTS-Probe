package config

import (
	"encoding/json"
	"log"
	"os"
)

// ProbeConfigParams contains all configuration parameters of the probe.
type ProbeConfigParams struct {
	// General configuration parameters of the probe.
	Name           string
	StatusInterval int
	Enabled        bool
	BridgeMode     bool

	// Configuration parameters for the eth0 interface.
	Subnet  string
	IP      string
	Mask    string
	Gateway string
	DNS     string

	// MQTT credentials for the broker of the test environment.
	MQTTURL      string
	MQTTUsername string
	MQTTPassword string

	// Configuration parameters for the bridge interface.
	BridgeIP          string
	BridgeMask        string
	BridgeDHCP        bool
	BridgeDHCPStart   string
	BridgeDHCPStop    string
	BridgeDHCPGateway string

	// Configuration parameters for the eth1 interface.
	Eth1IP          string
	Eth1Mask        string
	Eth1DHCP        bool
	Eth1DHCPStart   string
	Eth1DHCPStop    string
	Eth1DHCPGateway string

	// Configuration parameters for the eth2 interface.
	Eth2IP          string
	Eth2Mask        string
	Eth2DHCP        bool
	Eth2DHCPStart   string
	Eth2DHCPStop    string
	Eth2DHCPGateway string
}

// NewProbeConfigParams creates a new probe configuration. Default values are initialized first and then
// overridden by the configuration file if one is available.
func NewProbeConfigParams() ProbeConfigParams {
	probeConfig := ProbeConfigParams{}

	// Initialize the configuration with default values.
	probeConfig.SetDefaultConfigParams()

	// Load the configuration file specified by the environment variable.
	err := probeConfig.LoadProbe(os.Getenv("PROBE_CONFIG_PATH"))
	if err != nil {
		log.Println("[PROBE] No configuration found : Creating a new config file")
	} else {
		log.Println("[PROBE] Configuration found : Configuration load from the config file")
	}

	return probeConfig
}

// SetDefaultConfigParams initializes the probe configuration with predefined default values.
func (p *ProbeConfigParams) SetDefaultConfigParams() {
	p.Name = "Probe default"
	p.StatusInterval = 1
	p.Enabled = true
	p.BridgeMode = false

	// Default network configuration.
	p.IP = "10.0.0.80"
	p.Mask = "255.255.255.0"
	p.Gateway = "10.0.0.1"
	p.Subnet = "10.0.0.0/24"

	// MQTT configuration is initially empty and must be configured according to the deployment environment.
	p.MQTTURL = ""
	p.MQTTUsername = ""
	p.MQTTPassword = ""

	// Default configuration for the bridge.
	p.BridgeIP = "192.168.30.1"
	p.BridgeMask = "255.255.255.0"
	p.BridgeDHCP = false
	p.BridgeDHCPStart = "192.168.30.100"
	p.BridgeDHCPStop = "192.168.30.149"
	p.BridgeDHCPGateway = "192.168.30.10"

	// Default configuration for eth1.
	p.Eth1IP = "192.168.10.1"
	p.Eth1Mask = "255.255.255.0"
	p.Eth1DHCP = false
	p.Eth1DHCPStart = "192.168.10.100"
	p.Eth1DHCPStop = "192.168.10.149"
	p.Eth1DHCPGateway = "192.168.10.10"

	// Default configuration for eth2.
	p.Eth2IP = "192.168.20.1"
	p.Eth2Mask = "255.255.255.0"
	p.Eth2DHCP = false
	p.Eth2DHCPStart = "192.168.20.100"
	p.Eth2DHCPStop = "192.168.20.149"
	p.Eth2DHCPGateway = "192.168.20.10"
}

// SaveProbe saves the current probe configuration to a JSON file.
func (p *ProbeConfigParams) SaveProbe(filename string) error {
	log.Println("[PROBE-CONFIG] Saving probe config in the config file", filename)

	// Convert the configuration structure to formatted JSON.
	data, err := json.MarshalIndent(p, "", "  ")
	if err != nil {
		log.Println("[PROBE-CONFIG] Error saving probe config :", err)
		return err
	}
	log.Println("[PROBE-CONFIG] Writing probe config in the config file", filename)

	// Write the serialized configuration to the specified file.
	return os.WriteFile(filename, data, 0644)
}

// LoadProbe loads the probe configuration from a JSON file and updates the current configuration structure.
func (p *ProbeConfigParams) LoadProbe(filename string) error {
	log.Println("[PROBE-CONFIG] Loading probe config from the config file", filename)

	// Read the configuration file.
	data, err := os.ReadFile(filename)
	if err != nil {
		log.Println("[PROBE-CONFIG] Error reading the probe config file :", err)
		return err
	}

	// Unmarshal the JSON data into the configuration structure.
	err = json.Unmarshal(data, p)
	if err != nil {
		log.Println("[PROBE-CONFIG] Error unmarshaling the probe config file :", err)
		return err
	}

	return nil
}
