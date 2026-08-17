package capabilities

import "Code/models"

// CapabilitiesList Contains the list of the complete definition of every capability that the probe implements.
// All the capabilities of the list implements the format containing the metadata necessary to the coordinator display.
var CapabilitiesList = []models.Capability{
	PingCapability,
	CaptureCapability,
	PortscanCapability,
	HTTPCapability,
	UDPCapability,
	UDPServerCapability,
	TCPCapability,
	TCPServerCapability,
	PcapCapability,
}

// GetCapabilitiesList returns the list of the capabilities definition.
func GetCapabilitiesList() []models.Capability {
	return CapabilitiesList
}

// PingCapability fully defines the ping command.
var PingCapability = models.Capability{
	Action:      "ping",
	Label:       "Ping",
	Icon:        "network_ping",
	Description: "ICMP echo request test.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"},
		{Key: "target", Label: "Target", Type: "string", Example: "google.ch"},
		{Key: "count", Label: "Packet count", Type: "number", Example: 4, Min: 1, Max: 100},
		{Key: "timeout_ms", Label: "Timeout", Type: "number", Example: 1000, Min: 100, Max: 30000},
	},
	Expected: []models.Result{
		{Key: "packets_sent"},
		{Key: "packets_received"},
		{Key: "packet_loss_percent"},
		{Key: "rtt_min_ms"},
		{Key: "rtt_avg_ms"},
		{Key: "rtt_max_ms"},
	},
}

// CaptureCapability fully defines the capture command.
var CaptureCapability = models.Capability{
	Action:      "capture",
	Label:       "Capture",
	Icon:        "radio_button_checked",
	Description: "Capture network traffic (pcap).",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"},
		{Key: "filter", Label: "BPF Filter", Type: "string", Example: "ip"},
		{Key: "timeout_s", Label: "Duration", Type: "number", Example: 10, Min: 1, Max: 600, Unit: "s"},
	},
	Expected: []models.Result{
		{Key: "packet"},
		{Key: "pcap_b64"},
	},
}

// PortscanCapability fully defines the portscan command.
var PortscanCapability = models.Capability{
	Action:      "portscan",
	Label:       "Port Scan",
	Icon:        "search",
	Description: "Scan ports on a target host.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"},
		{Key: "target", Label: "Target Host", Type: "string", Example: "google.ch"},
		{Key: "ports", Label: "Port(s)", Type: "string", Example: "80,443,8000-8020,8080"},
		{Key: "sV", Label: "Enable Service Detection", Type: "boolean", Example: false},
	},
	Expected: []models.Result{
		{Key: "ports"},
	},
}

// HTTPCapability fully defines the http command.
var HTTPCapability = models.Capability{
	Action:      "http",
	Label:       "HTTP Request",
	Icon:        "language",
	Description: "Send HTTP requests.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"},
		{Key: "method", Label: "Method", Type: "select", Options: []models.Options{{Value: "GET", Label: "GET"}, {Value: "POST", Label: "POST"}, {Value: "PUT", Label: "PUT"}, {Value: "PATCH", Label: "PATCH"}, {Value: "DELETE", Label: "DELETE"}, {Value: "HEAD", Label: "HEAD"}, {Value: "OPTIONS", Label: "OPTIONS"}}, Example: "GET"},
		{Key: "header", Label: "Header", Type: "keymap", Example: map[string]string{
			"User-Agent":   "Probe-HTTP-Executor",
			"Content-Type": "application/json",
		}},
		{Key: "url", Label: "URL", Type: "string", Example: "https://google.ch"},
		{Key: "body", Label: "Body", Type: "body", Example: "{}"},
	},

	Expected: []models.Result{
		{Key: "response"},
	},
}

// UDPCapability fully defines the udp command.
var UDPCapability = models.Capability{
	Action:      "udp",
	Label:       "UDP",
	Icon:        "send",
	Description: "Send UDP requests.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"}, // local IP
		{Key: "source-port", Label: "Source port", Type: "number", Example: "8080"},
		{Key: "destination-ip", Label: "Desination IP", Type: "string", Example: "192.168.3.130"}, // remote IP
		{Key: "destination-port", Label: "Desination Port", Type: "number", Example: "8080"},
		{Key: "data", Label: "Data", Type: "string", Example: "Ich liebe das Leben."},
		{Key: "waiting-response", Label: "Waiting response", Type: "bool", Example: false},
	},
	Expected: []models.Result{
		{Key: "response"},
	},
}

// UDPServerCapability fully defines the udp echo server command.
var UDPServerCapability = models.Capability{
	Action:      "udp-server",
	Label:       "UDP echo server",
	Icon:        "sync_alt",
	Description: "Create a UDP echo server.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"}, // local IP
		{Key: "port", Label: "Source port", Type: "number", Example: "8080"},
		{Key: "timeout_s", Label: "Duration", Type: "number", Example: 10, Min: 1, Max: 600, Unit: "s"},
	},
	Expected: []models.Result{
		{Key: "response"},
	},
}

// TCPCapability fully defines the tcp command.
var TCPCapability = models.Capability{
	Action:      "tcp",
	Label:       "TCP",
	Icon:        "send",
	Description: "Send TCP requests.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"},
		{Key: "source-port", Label: "Source port", Type: "number", Example: "8080"},
		{Key: "destination-ip", Label: "Desination IP", Type: "string", Example: "192.168.3.130"},
		{Key: "destination-port", Label: "Desination Port", Type: "number", Example: "8080"},
		{Key: "data", Label: "Data", Type: "string", Example: "Ich liebe das Leben."},
		{Key: "waiting-response", Label: "Waiting response", Type: "bool", Example: false},
	},
	Expected: []models.Result{
		{Key: "response"},
	},
}

// TCPServerCapability fully defines the tcp echo server command.
var TCPServerCapability = models.Capability{
	Action:      "tcp-server",
	Label:       "TCP echo server",
	Icon:        "sync_alt",
	Description: "Create a TCP echo server.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"},
		{Key: "port", Label: "Source port", Type: "number", Example: "8080"},
		{Key: "timeout_s", Label: "Duration", Type: "number", Example: 10, Min: 1, Max: 600, Unit: "s"},
	},
	Expected: []models.Result{
		{Key: "response"},
	},
}

// PcapCapability fully defines the PCAP sending command.
var PcapCapability = models.Capability{
	Action:      "pcap-file",
	Label:       "Send pcap file",
	Icon:        "upload_file",
	Description: "Rerun a pcap file.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"},
		{Key: "filter", Label: "BPF Filter", Type: "string", Example: "src host 192.168.3.130"},
		{Key: "file", Label: "Pcap file", Type: "pcap", Example: ""},
	},
	Expected: []models.Result{},
}
