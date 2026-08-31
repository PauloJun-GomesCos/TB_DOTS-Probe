// Style des blocs de code
#let endpoint(path) = box(
  fill: rgb("#e9e9eb"),
  radius: 3pt,
  inset: (x: 3pt, y: 2pt),
  outset: 0pt,
  stroke: none,
)[
  #text(
    font: "DejaVu Sans Mono",
    size: 7pt,
    weight: "bold",
  )[
    #path
  ]
]

#page(fill: white)[

	= Extending the Probe
	This guide provides practical informations for extending the probe. It explains how to add a new capability, configuration group, or configuration parameter while ensuring that the required metadata is included in the announce message and can therefore be displayed correctly in the coordinator web interface.

	== Add a new capability
	A capability represents a command that can be executed by the probe. Adding a new capability requires three main steps:

	1. Implement the command executor.
	2. Register the executor.
	3. Define and register the capability metadata.

	*1. Implement the command executor*

	Create a new #endpoint(".go") file in the #endpoint("probe.services") package and implement the function responsible for executing the command.

	The function must follow the executor interface used by the probe. 

	For example:
	```go
		func PingExecute(msgCommand models.MsgCommandRequest, p *probe.Probe)
	``` 
	The executor is responsible for processing the command and sending the appropriate response to the coordinator.

	Depending on the execution process, it can use the following response functions implemented in the #endpoint("probe.probe") package:

	- *SendSuccessResponse*: sends the final successful result.
	- *SendProcessingResponse*: informs the coordinator that the command start being processed.
	- *SendErrorResponse*: reports an error during command execution.

	For example, an executor for a new #endpoint("example") capability could be implemented in #endpoint("example.go") in the function #endpoint("func ExampleExecute(msgCommand models.MsgCommandRequest, p *probe.Probe)").

	*2. Register the executor*

	Once the executor has been implemented, it must be registered in the Executors map in the #endpoint("probe.app") package.

	The _key_ of the map corresponds to the *command name* received by the probe, while the _value_ corresponds to the *executor function*.

	For example:
	```go
		// Register the executors available for processing commands.
		Probe.Executors["ping"] = services.PingExecute
		Probe.Executors["capture"] = services.CaptureExecute
		Probe.Executors["portscan"] = services.PortscanExecute
		Probe.Executors["http"] = services.HTTPExecute
		Probe.Executors["udp"] = services.UDPExecute
		Probe.Executors["udp-server"] = services.UDPServerEchoExecute
		Probe.Executors["tcp"] = services.TCPExecute
		Probe.Executors["tcp-server"] = services.TCPServerEchoExecute
		Probe.Executors["pcap-file"] = services.PcapExecute
	```

	To add a new capability called #endpoint("example"), the following entry must be added:
	```go
		Probe.Executors["example"] = services.ExampleExecute
	```

	*3. Define the capability metadata*

	The capability must then be described by creating a new variable of type #endpoint("models.Capability") structure in the #endpoint("probe.capabilities") package. This variable defines all the metadata required by the coordinator to display and configure the capability in its web interface.

	The variable should follow the naming convention #endpoint("\<CapabilityName>Capability"). For example, a capability named #endpoint("Example") should be defined as #endpoint("ExampleCapability").

	Here is an example of this structure for the ping command:
	```go
	// PingCapability fully defines the ping command
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
	```


	#colbreak()

	*4. Add the capability to the capability list*

	Finally, the new capability must be added to #endpoint("CapabilitiesList") in the #endpoint("probe.capabilities") package.

	For example:
	```go
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

		ExampleCapability, 		// New example capability
	}
	```

	Adding the capability to this list ensures that its metadata is included in the probe's *announcement message*.

	== Add a New Configuration Group
	A configuration group is used to organize related configuration parameters in the coordinator web interface.

	Adding a new configuration group only requires adding a new entry to the list returned by the function #endpoint("SetConfigGroupList()"), implemented in the #endpoint("probe.probe") package.

	*1. Add the configuration group*

	The current configuration groups are defined as follows:
	```go
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
	```

	To add a new group, add another #endpoint("models.Group") entry.

	The group name defined in the _Key_ field must be used as the value of the _Group_ field when creating a configuration parameter. This associates the parameter with the corresponding configuration group.


	== Add a New Configuration Parameter

	Adding a configuration parameter requires defining the parameter in the probe configuration, setting its default value, allowing it to be updated, and finally exposing its metadata to the coordinator.

	*1. Add the parameter to the configuration structure*

	First, add the new configuration parameter field to #endpoint("ProbeConfigParams") struct, implemented in the #endpoint("probe.config") package.

	*2. Define a default value*

	Add a default value for the new parameter in the funtion #endpoint("SetDefaultConfigParams"), also implemented in the #endpoint("probe.config") package.

	This ensures that the parameter has a valid value when no value is explicitly provided in the configuration file.

	*3. Allow the parameter to be updated*

	The new configuration parameter must also be added to the #endpoint("ValidateControlParams(...)") function, implemented in #endpoint("probe_HandleControl.go") in the #endpoint("probe.probe") package.

	This function is responsible for validating the parameters received when the coordinator requests a configuration update. The parameter must therefore be explicitly added to the list of accepted parameter names. Otherwise, any update request containing the new parameter will be rejected by the probe with the following error:

	Inavalid parameter name: ...

	In other words, adding the parameter to #endpoint("ProbeConfigParams") only defines the parameter in the probe configuration. It must also be added to #endpoint("ValidateControlParams(...)") so that the probe accepts it when receiving configuration updates from the coordinator.

	*4. Add the parameter metadata*

	Finally, add the parameter to the function #endpoint("SetConfigParamsList()").

	This function defines the metadata required by the coordinator to display the parameter and its current value in the web interface.


	#colbreak()

	For example:
	```go
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

			...

			}
		return Config
	}
	```
	The _Group_ field determines in which configuration group the parameter is displayed.

	#colbreak()
]