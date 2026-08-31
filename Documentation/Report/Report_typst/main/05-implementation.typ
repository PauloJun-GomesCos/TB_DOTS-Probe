#import "../metadata.typ": *

#import "../resources/diagram/fit.typ": fit
#import "/resources/diagram/MQTT-Communication-content.typ": (
  mqtt-setup-sequence, mqtt-setup-sequence-size, mqtt-command-sequence, mqtt-command-sequence-size, mqtt-discovery-sequence, mqtt-discovery-sequence-size,
)

#import "/resources/diagram/State-Machine.typ": (
  state-machine, state-machine-size
)

#pagebreak()
= #i18n("implementation-title", lang:option.lang) <sec:impl>

#show raw: set text(size: 7pt)
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

#option-style(type:option.type)[
  In the implementation phase of your bachelor thesis, you translate the design specifications into tangible, functional artifacts. This section offers insights into the practical execution of your research, detailing the steps taken to realize the proposed system. Here are some ways to enhance and elaborate on this section:

  - *Development Methodology*: Describe the methodology or approach employed in the development process.
  - *Prototyping and Iterative Development*: If applicable, discuss any prototyping or iterative development techniques utilized during the implementation phase.
  - *Coding Practices and Standards*: Provide insights into the coding practices, standards, and conventions adhered to during development.
  - *Testing and Quality Assurance*: Detail the testing strategies and quality assurance measures employed to validate the correctness and robustness of the implemented system.
  - *Performance Optimization*: Address any performance considerations or optimizations made during the implementation phase.
  - *Deployment and Configuration*: Describe the deployment process and configuration management practices involved in deploying the system to production or testing environments.
  - *Documentation and Knowledge Transfer*: Highlight the importance of documentation in facilitating knowledge transfer and ensuring the sustainability of the implemented system.
]

This section presents the implementation of the probe and details the main components developed during the project. It first describes the implementation of the probe's overall workflow and its connection to the broker, followed by the communication with the coordinator and the definition of the formats used for configurations and capabilities, including the metadata required for their display in the coordinator web interface. The configuration of the network interfaces is then presented, followed by a detailed description of the different capabilities implemented on the probe.

#add-chapter(
  after: <sec:impl>,
  before: <sec:proof>,
  minitoc-title: i18n("toc-title", lang: option.lang)
)[
  #pagebreak()

  == Implementation of the probe workflow
  The probe workflow is implemented as a state machine composed of three states: *StateStarting*, *StateRunning*, and *StateConnecting*. Each state is responsible for a specific part of the probe's lifecycle, from its initial configuration to normal operation and connection recovery.

  During *StateStarting*, the probe is created and loads its configuration from the JSON configuration file. It then searches for an available MQTT broker on the coordination network. Depending on the environment, this can be either the configuration broker or the test broker. Once an available broker is detected, the MQTT client is configured with the corresponding connection parameters and attempts to establish a connection. After the connection has been successfully established, the probe subscribes to the required MQTT topics and associates a callback function with each topic. Once the connection and all required subscriptions are successfully established, the probe transitions to *StateRunning*.

  In *StateRunning*, the probe first announces itself to the coordinator by publishing an *announcement message* containing its capabilities and configurable parameters. It then starts periodically sending status messages and waits for incomming message from the coordinator. When a message is received, the callback associated with its topic processes the message and triggers the appropriate action. If the probe loses its connection to the MQTT broker, the MQTT client generates an *EventMQTTDisconnected* event. The probe stops its periodic status messages and transitions to *StateConnecting*. 
  
  The *StateConnecting* is responsible for recovering the MQTT connection. It continuously searches for an available broker on its coordination network. When a broker becomes available, the MQTT client is reconfigured with the corresponding parameters and attempts to establish a new connection. If the connection succeeds, the client generates an *EventMQTTConnected* event. The probe then restores its subscriptions and transitions back to *StateRunning*. If the connection attempt fails, the client generates an *EventMQTTConnectionFailed* event, and the probe remains in *StateConnecting* and continues searching for an available broker.

  #figure(
    fit(state-machine-size.w - 3.5cm, state-machine-size.h, state-machine()),
    caption: [State machine that implement the probe workflow],
  ) <state-machine>

  #colbreak()

  == Broker detection and connection
  As explained, the probe is designed to operate in two different environments: the *configuration environment* and the *test environment*. Each environment has its own MQTT broker. The probe must therefore have two broker configurations, each allowing it to establish a connection with one of the two brokers:

  - *BrokerConfigParams* : configuration of the broker used by the configuration environment
  - *TestBrokerParams* : configuration of the broker used by the test environment

  The *BrokerConfigParams* parameters are defined in the #endpoint(".env") file and loaded when the probe starts. They cannot be modified while the program is running: any change to the #endpoint(".env") file requires the probe to be restarted to take effect. The *TestBrokerParams* parameters, on the other hand, are part of the probe's internal configuration and can be modified while it is running when a configuration message is received on #endpoint("probes/{probe_id}/control").

  Once both configurations are available, the probe must determine which broker is reachable from its *coordination network* (eth0). To do so, it attempts to establish a *TCP connection* with each configured broker. When a connection is successfully established with one of them, the probe identifies the broker available on its network and can therefore determine which environment it is operating in. This information is important because the configuration of the network interfaces of the probe, differs between the two environments.

  Once the broker has been identified, the MQTT client is configured with the corresponding parameters and it connects to the avalaible broker. After the connection is established, the MQTT client subscribe to the different topics required for its operation.

  This mechanism is also used when the MQTT connection is lost (*StateConnecting*). Whenever a *disconnection* occurs, the probe searches again for the broker accessible from its network. As soon as a TCP connection is established with one of the brokers, that broker is identified and the probe MQTT client is *reconfigured* with the corresponding parameters. The probe can then attempt to establish a new MQTT connection and resubscribe to the required topics.

  This approach allows the probe to automatically adapt to a change of environment without requiring a restart.

  == Implementation of the communication with the coordinator
  During the initialization of the probe (*StateStarting*), a map is created to associate each subscribed MQTT topic with its corresponding callback function. This allows the MQTT client to automatically call the appropriate function when a message is received. Each type of message is therefore handled by a dedicated callback, keeping the logic associated with each topic separate.

  #colbreak()

  Three callback functions were defined:
  - *handleDiscover* (for the message received on #endpoint("probes/discover"))
  - *handleControl* (for the message received on #endpoint("probes/{probe_id}/control"))
  - *handleCommand* (for the message received on #endpoint("probes/{probe_id}/command"))
  
  These callback functions are implemented in the #endpoint("probe.probe") package. When a message is received on one of the topics, the MQTT client automatically calls the associated callback function and passes the message payload as a parameter. The function can then process the message and perform the corresponding operations.

  The following subsections illustrate, using sequence diagrams, how the communication with the coordinator takes place.

  === Discovery request and status
  #figure(
    fit(mqtt-discovery-sequence-size.w - 2cm, mqtt-discovery-sequence-size.h, mqtt-discovery-sequence()),
    caption: [Sequence diagram - Discovery request and status heartbeat],
  ) <Disc-sequence>

  When the probe receives a discovery message on the #endpoint("probes/discover") topic, it announces its presence again by sending an *announcement message* on the #endpoint("probes/announce") topic. 
  
  As soon as a message is received on #endpoint("probes/discover"), the *handleDiscover* callback function is executed. Its sole purpose is to send the *announcement message* using the _request_id_ received in the discovery message.

  The probe also periodically publishes *status messages* (heartbeat mechanism). To send these messages periodically, a dedicated function is started in a *goroutine* running alongside the rest of the system. This function is implemented in the #endpoint("probe.status") package and is responsible only for sending *status messages*. The goroutine is stopped when the connection to the broker is lost and restarted when the connection is re-established. A channel is used to notify the goroutine when the probe configuration is updated (#endpoint("probes/{probe_id}/control")). This allows the goroutine to receive the updated configuration of the probe and adjust the interval between status messages accordingly.

  === Configuration request
  #figure(
    fit(mqtt-setup-sequence-size.w - 2cm, mqtt-setup-sequence-size.h, mqtt-setup-sequence()),
    caption: [Sequence diagram - Control request],
  ) <Control-sequence>

  When the probe receives a *configuration message* on the #endpoint("probes/{probe_id}/control") topic, it must update its settings and send a *response message* on the #endpoint("probes/{probe_id}/responce") topic. The response can either be a *success response* if the probe was updated successfully, or an *error response* if the update failed. 
  
  As soon as a message is received on #endpoint("probes/{probe_id}/control"), the *handleControl* callback function is executed. This function first checks whether the received parameters are valid and consistent. If they are, it updates the probe's configuration and saves the new parameters in the configuration JSON file. This file provides persistent storage for the probe's configuration, allowing the settings to be restored after a restart.

  After each configuration change, the probe sends an *announcement message* on the #endpoint("probes/announce") topic to provide the coordinator with an up-to-date view of the probe's configuration.

  === Command request
  #figure(
    fit(mqtt-command-sequence-size.w - 2cm, mqtt-command-sequence-size.h, mqtt-command-sequence()),
    caption: [Sequence diagram - Command request],
  ) <Command-sequence>

  When the probe receives a *command message* on the #endpoint("probes/{probe_id}/command") topic, it must execute the requested command and send its result in a *response message* on the #endpoint("probes/{probe_id}/response") topic.

  For a command, three types of response messages can be sent:
  - *Success response*: sent if no error occurs during the validation or execution of the command. Contains the results obtained after the command has been executed.
  - *Error response*: sent if an error occurs during the validation or execution of the command. Contains the error composed of its error code and message
  - *Processing response*: sent when a command requires a longer execution time or involves operations that need to run in parallel, such as a capture or a port scan. This message informs the coordinator that the command has started and allows it to continue processing other operations without waiting for the final result. The final response is sent once the command has completed.

  During the probe's initialization (*StateStarting*), a map of executors is created, associating each command name with its corresponding executor function (for example, "ping" → #endpoint("pingExecute())"). These functions are implemented in the #endpoint("probe.services") package, and their operation is described later in this report.

  When a message is received on the #endpoint("probes/{probe_id}/command") topic, the handleCommand function is executed. This function first checks whether the received parameters are valid. If they are, it uses the _action_ field from the command message to find the corresponding executor in the executor map. The selected executor function is then executed in a goroutine, allowing multiple commands to run in parallel without blocking the rest of the probe.
  
  == Implementation of the configuration paramaters list
  This section of the implementation explain how the list of configuration parameters are defined before being sent to the coordinator through the announcement message (#endpoint("probes/announce")). As explained previously, each configuration parameter is defined with all the metadatas required for the coordinator's web interface to display it.

  To achieve this, a generic configuration parameter format containing all the necessary information was defined. The structure of this message is located in the #endpoint("models") package and is defined by the #endpoint("Param") structure.

  Some configuration parameters are grouped together in a parameter group. This is, for example, the case for the parameters related to the MQTT credentials or to a specific network interface. These groups also needs to contain some metadata to enable the coordinator to correctly display them on the web interface, so a format was also defined and its defined by the #endpoint("Group") structure.

  The following sections first describe how these parameter groups are defined, then it explain the definition of the configuration paramaters.

  === Format of the configuration parameters groups

  The list of configuration groups currently implemented in the system are defined below:
  ```json
  {
    "config_groups": [
      {"key": "network", "label": "Network", "icon": "lan"},
      {"key": "mqtt", "label": "MQTT credentials", "icon": "hub"},
      {"key": "bridge", "label": "Bridge", "icon": "device_hub",
       "visible_if": {"key": "bridge_mode", "value": true}
      },
      {"key": "eth1", "label": "Interface eth1", "icon": "settings_ethernet", 
       "visible_if": {"key": "bridge_mode", "value": false}
      },
      {"key": "eth2", "label": "Interface eth2", "icon": "settings_ethernet",
       "visible_if": {"key": "bridge_mode", "value": false}
      },
    ],
  }
  ```
  
  The Network group contains the configuration parameters of the coordination interface (eth0) of the probe, while MQTT credentials contains the information required to connect with the MQTT broker of the test environment. The Bridge group contains the parameters related to the bridge configuration and is displayed when bridge mode is enabled. When bridge mode is disabled, the interfaces eth1 and eth2 groups are displayed instead, allowing each test interface to be configured individually.
  
  #colbreak()

  The different fields of a configuration group (#endpoint("Group") struct) are described below. The fields shown in bold are mandatory for all the configuration parameters groups.
  #figure(
    table(
      columns: (2fr, 8fr),
      align: left,

      table.header(
        [*Field*],
        [*Description*],
      ),

      [*key*], [The name used to identify the group in the configuration parameters.],
      [*label*], [The name of the group displayed in the web interface.],
      [*icon*], [The icon associated with the group. The icon name can be any *Google Material Icon* name, written in lowercase with spaces replaced by underscores.],
      [visible_if], [Defines a display condition. The group is displayed only when this condition is satisfied.],
    ),
    caption: [Fields description of a configuration group format],
  ) <tbl:Field-ConfigGroups>

  The _visible_if_ field contains two sub-fields, *_key_* and *_value_*. The key specifies the name of a probe configuration parameter, while value specifies the value that this parameter must have for the group to be displayed in the web interface. For example, in the configuration groups presented above, the bridge group, including all of its associated parameters, is only displayed when the _bridge_mode_ parameter is set to true. This mechanism allows the web interface to display only the configuration parameters that are relevant to the current probe configuration, keeping the interface more concise and easier to use.

  The list of the configuration groups is defined by a function of the #endpoint("probe.probe") package. This function is called #endpoint("SetConfigGroupsList") and it returns a #endpoint("[]models.Group"). The probe includes this list in every *announcment message*. Adding a new configuration group to the *announcement message* requires to add new entry in the list implemented by this function.

  === Format of the configuration parameters list

  The following is an excerpt from the list of configuration parameters provided by the probe:
  ```json
  {    
    "config" : [
      {"key" : "name", "label" : "Name", "type" : "string", "value" : "Probe LAN"},
      {"key" : "status_interval_s", "label" : "Status interval", "type" : "string", "value" : "1"},
      {"key" : "enable", "label" : "Enabled", "type" : "bool", "value" : "true"},
      {"key" : "bridge_mode", "label" : "Bridge activated", "type" : "bool", "value" : "false"},
      {"key" : "ip", "label" : "IP address", "type" : "string", "value" : "10.0.0.80", "group" : "network"},
      ...
    ],
  }
  ```

  #colbreak()

  The different fields of a configuration parameter (#endpoint("Param") struct) are described below:
  
  #figure(
    table(
      columns: (2fr, 8fr),
      align: left,

      table.header(
        [*Field*],
        [*Description*],
      ),

      [*key*], [The name used to identify the configuration parameter. This key is used when sending the configuration parameter through the #endpoint("probes/{probe_id}/control") message.],
      [*label*], [The name of the configuration parameter displayed in the web interface.],
      [*type*], [The type of value that can be provided for the parameter.],
      [*value*], [The acctual value assigned to the configuration parameter.],
      [group], [The name of the configuration group to which the parameter belongs. This field is optional.],
    ),
    caption: [Fields description of a configuration parameter format],
  ) <tbl:Field-ConfigParams>
  
  The list of the configuration parameters is defined by a function of the #endpoint("probe.probe") package. This function is called #endpoint("SetConfigParamsList") and it returns a #endpoint("[]models.Param"). The probe includes this list in every *announcment message*. Adding a new configuration parameter to the *announcement message* requires to add new entry in the list implemented by this function.

  == Implementation of the capabilities list
  This section of the implementation explain how the commands list is defined before being sent to the coordinator through the announcement message (#endpoint("probes/announce")). As explained previously, each command must be fully defined by the probe. This includes not only the information required to execute the command, but also all the metadata required to display and configure the command in the coordinator's web interface.

  To achieve this, a capability format containing all the information required by the coordinator to display a command was defined. The structure of this message is located in the #endpoint("models") package and is defined by the #endpoint("Capability") struct.

  The following example shows the capability definition for the ping command:
  ```json
  {
    "capabilities" :[
      {
        "action" : "ping",
        "label" : "Ping",
        "icon" : "network_ping",
        "description" : "ICMP echo request test.",
        "params" : [
          {"key" : "interface", "label" : "Interface", "type" : "string", "example" : "eth1"},
          {"key" : "target", "label" : "Target", "type" : "string", "example" : "google.ch"},
          {"key" : "count", "label" : "Packet count", "type" : "number", "example" : "4", "min" : 4, "max" : 100},
          {"key" : "timeout_ms", "label" : "Timeout", "type" : "number", "example" : "1000", "min" : 100, "max" : 30000}
        ],
        "result": [
          {"key": "packets_sent"},
          {"key": "packets_received"},
          {"key": "packet_loss_percent"},
          {"key": "rtt_min_ms"},
          {"key": "rtt_avg_ms"},
          {"key": "rtt_max_ms"}
        ]
      },
      ...
    ]
  }
  ```

  The different fields of this message are described below:

  #figure(
    table(
      columns: (2fr, 8fr),
      align: left,

      table.header(
        [*Field*],
        [*Description*],
      ),

      [*action*], [The name of the command that must be provided in the _action_ field of the command message (#endpoint("topic probes/{probe_id}/command"))],
      [*label*], [The name of the command displayed in the web interface.],
      [*icon*], [The icon representing the command in the web interface. The icon name can be any *Google Material Icon* name, written in lowercase with spaces replaced by underscores.],
      [*description*], [A short description of the command.],
      [*params*], [The list of parameters required to execute the command. Each parameter follows a specific format (#endpoint("CapabilityParam") struct), which is described below.],
      [*result*], [The list of results expected after the command is executed. Each result follows a specific format (#endpoint("Result") struct), which is described below.],
    ),
    caption: [Fields description of the Capability format],
  ) <tbl:Fields-capability>

  #colbreak()

  The fields of the format for a command parameter (#endpoint("CapabilityParam") struct) is described below. The fields shown in bold are mandatory for all parameters of every command:
  #figure(
    table(
      columns: (2fr, 8fr),
      align:left,

      table.header(
        [*Field*],
        [*Description*],
      ),

      [*key*], [The name of the parameter that must be provided in the #endpoint("params") field of the command message.],
      [*label*], [The name of the parameter displayed in the web interface.],
      [*type*], [The type of value that must be provided for the parameter.],
      [*example*], [An example of a possible value for the parameter, displayed to the user in the web interface.],
      [min], [The minimum value allowed for the parameter. This can be used to define limits in the web interface.],
      [max], [The maximum value allowed for the parameter. This can be used to define limits in the web interface.],
      [unit], [The unit associated with the parameter.],
      [options], [The possible values for the parameter when it must be selected from a predefined list. For example, this is used by the *http* command to select the HTTP method (GET, PUT, ...)],
    ),
    caption: [Fields description of the CapabilityParams format],
  ) <tbl:Fields-capability>

  The expected results format is defined using a single field, *_key_*. This field is mandatory and contains the name of the result sent by the probe in the response message (#endpoint("probes/{probe_id}/response")).

  The definitions of all command descriptions are located in the #endpoint("probe.capabilities") package as variables implementing the format described above (#endpoint("models.Capability")). These variables are then grouped into a variable of type #endpoint("[]models.Capability"), called #endpoint("capabilities.CapabilitiesList"). The probe stores this list in its configuration and includes it in every *announcement message*.
  
  Adding a new command to the *announcement message* therefore only requires creating a variable implementing the #endpoint("models.Capability") structure and adding it to the #endpoint("capabilities.CapabilitiesList") list.

  == Configuration of the interfaces
  This section describes the configuration of the probe's network interfaces. As explained previously in the requirements section, the interfaces must be configurable to meet the network requirements of the different environments in which the probe can be deployed.

  As described earlier, the system consists of two separate environments: the *configuration environment* and the *test environment*. In the configuration environment, the coordination network provides the probe with an IP address through DHCP. However, the coordination network in the test environment may not provide a DHCP server. It is therefore necessary to be able to configure a static IP address for the probe's *eth0* interface, allowing it to use an address belonging to the coordination network of the test environment (#endpoint("10.0.0.0/24") of the dual environment diagram). The same requirement applies to the interfaces connected to the test network (*eth1* and *eth2*). Since this network may also operate without a DHCP server, the probe must be able to assign static IP addresses to these interfaces. This allows an IP address compatible with the test network of the test environment to be manually defined when deploying the probe.

  The two interfaces connected to the test network must also be able to operate in bridge mode. In this configuration, *eth1* and *eth2* are combined into a single bridge interface (*br0*) allowing traffic to be transparently forwarded between the two interfaces.

  The ability to run a DHCP server on one of the probe's interfaces was also implemented. This was not a major requirement for the intended operation of the system, but it proved useful for debugging and testing during the development of the probe.

  The implementation of these different features is described in the following subsections. To implement these features, the #endpoint("network") package was developed using the netlink library. All parameters required for network configuration are received through the configuration message (#endpoint("probes/{probe_id}/control")) sent by the coordinator. These parameters are divided into different groups depending on the part of the network configuration they concern. 

  === Configuration of IP address
  It is necessary to distinguish between two types of IP configuration in this system:
  - Coordination network
  - Test network
  The IP configuration for these two networks is implemented differently for several reasons, which will be explained in the following sections.

  To configure an IP address on a test network interface (eth1, eth2, or bridge), the following parameters are required: 

  #figure(
    table(
      columns: (2fr, 8fr),
      align: left,

      table.header(
        [*Parameter*],
        [*Description*],
      ),

      [*IP*], [The IP address to assign to the interface. It must be provided in IPv4 format (example: 10.0.0.80).],
      [*Mask*], [The subnet mask in dotted-decimal notation (example: 255.255.255.0).],
    ),
    caption: [Configuration parameters for a test interface],
  ) <tbl:TestInterface-parameters>

  The configuration of a test network interface is performed as follows. First, the interface is reset by removing all of its existing IP addresses. If the *IP parameter* is _null_, the DHCP client is enabled on the interface, which then waits to receive a dynamic IP address from a DHCP server. If the *IP parameter* is _not null_, the DHCP client is disabled and the specified IP address is assigned to the interface together with its configured subnet mask (*Mask parameter*). This mechanism allows the test network interfaces to be configured with either a static or a dynamic IP address. 
  
  In the current version of the probe, the gateway of the test interfaces cannot be configured. A future improvement could therefore be to allow gateway configuration on these interfaces to support networks requiring specific routing.

  #colbreak()

  To configure the IP address of the coordination network interface (eth0), the following parameters are required: 

  #figure(
    table(
      columns: (2fr, 8fr),
      align: left,

      table.header(
        [*Parameter*],
        [*Description*],
      ),

      [*IP*], [The IP address to assign to the interface. It must be provided in IPv4 format (example: 10.0.0.80).],
      [*Mask*], [The subnet mask in dotted-decimal notation (example: 255.255.255.0).],
      [*Gateway*], [The gateway of the coordination network.],
      [*Subnet*], [The subnet of the coordination network in the test environment. It must be provided in CIDR notation (example: 10.0.0.0/24).],
    ),
    caption: [Configuration parameters for the coordination interface],
  ) <tbl:TestInterface-parameters>

  The configuration of the coordination network interface is handled differently from the test network interfaces. First, all IP addresses belonging to the network specified by the *Subnet parameter* are removed from *eth0*. This partial reset ensures that only the IP addresses associated with the test environment's coordination network are removed. This is important when the probe is connected to the configuration environment, as the IP address (received by the DHCP server of the configuration environement) used to communicate with the configuration MQTT broker must not be removed when configuring *eth0*. After this partial reset, if the *IP parameter* is _null_, the DHCP client is enabled on eth0, allowing the interface to obtain an IP address dynamically. If the *IP parameter* is _not null_, the environment to which the probe is connected is first determined. If the probe is connected to the *configuration environment*, the specified IP address is assigned to eth0 and the gateway is configured according to the *Gateway parameter*. The DHCP client remains enabled in this case. If the probe is connected to the *test environment*, the specified IP address and gateway are configured and the DHCP client is disabled. This distinction is important because disabling the DHCP client in the *configuration environment* would cause the probe to lose the IP address used to communicate with the configuration broker, resulting in a loss of connectivity with the broker.

  === Creation of a bridge
  To create a bridge, the _bridge\_mode_ configuration parameter of the probe must be enabled. When this parameter is enabled, the probe creates a bridge interface named *br0* and configures it in the same way as the other test network interfaces (*eth1* and *eth2*). The procedure for configuring a test network interfaces was explained in the previous subsection.

  #colbreak()

  === Configuration of a DHCP server
  To configure a DHCP server on an interface, the following parameters are required: 

  #figure(
    table(
      columns: (2fr, 5fr),
      align: left,

      table.header(
        [*parametre*],
        [*Description*],
      ),

      [*DHCP activated*], [Boolean value determining whether the DHCP server should be enabled or disabled.],
      [*DHCP start adress*], [The first IP address of the DHCP address range.],
      [*DHCP stop address*], [The last IP address of the DHCP address range.],
      [*DHCP gateway*], [The gateway provided to clients by the DHCP server.],
    ),
    caption: [Configuration parameters for the DHCP server configuration],
  ) <tbl:TestInterface-parameters>

  When required, the DHCP server is created using #endpoint("dnsmasq")@dnsmasq. Only interfaces belonging to the test network (eth1, eth2 or br0) can have a DHCP server configured.

  === Issue encountered
  When we configure a *static IP* address on an interface, the DHCP client is disabled. It implies that the OS no longer knows the DNS of the *coordination network*. As a consequence I was unable to update my probe from the test environement (pull a new version of the image from #endpoint("ghcr.io")), despite the fact that the environement had internet. I tried several methods to solve this problem, but I was unable to resolve it. I tried modifying the informations in the OS's #endpoint("/etc/resolv.conf") file, but modifying the OS information from Docker container is complex. Following a discussion with the professor responsible for the Bachelor thesis, we concluded that it was not necessary to continue trying to solve this behavior, considering that is was outside the scope of this thesis and the time planned for this thesis was coming to an end. So pulling a new versions is only possible in the *configuration environement*, which always provides the probe with an IP address through DHCP and therefore also provides it with DNS information.
  
  The absence of known DNS server in the OS's #endpoint("/etc/resolv.conf") caused another problem. When the OS starts, Docker copies the OS's #endpoint("/etc/resolv.conf") into its own #endpoint("/etc/resolv.conf"). Since the DHCP client of *eth0* is enabled by default when the OS starts, the Docker container #endpoint("/etc/resolv.conf") initially contains the DNS informations provided by the DHCP. This happens because Docker copies the file before the probe program starts and configures a static IP address on *eth0*. As a result, after the startup, the Docker container knows the DNS server and the probe can resolve hostnames, allowing it to ping google.ch for example. However, when the Docker container is stopped (*docker compose down*) and started again (*docker compose up*), Docker updates its #endpoint("/etc/resolv.conf") by copying the OS's file again that doesn't contains the DNS. Therefore, after restarting the Docker container, the probe is was no longer able to resolve hostnames such as google.ch. This situation caused inconsistent behavior in the probe, so I tried to find a solution. During these tests, I used #endpoint("net.Resolver") to force my program to resolve hostnames using a custom DNS server. The tests with this approach were relatively conclusive. However, this does not solve the initial problem of the missing DNS information in the OS. 

  The way #endpoint("net.Resolver") was used is explained in the section dedicated to the net.Resolver proof of concept.

  == Implementation of the capabilities
  During this thesis, several capabilities were implemented in the probe to allow it to perform different types of tests. This section describes the implemented commands, their prupose, the parameters required to execute them, and the results they provide. All the commands ares implemented in the #endpoint("probe.services") packet.

  Although each command performs a different operation, their execution follows a common process. When the execution function is called, the command parameters are first validated to ensure that they are correct and complete. If an error is detected during this validation, the probe sends an error response to the coordinator through the #endpoint("probes/{probe_id}/response") topic. This response contains the error code and the corresponding error message. 
  
  If the parameters are valid, the execution of the command can begin. For commands that may take some time to complete (capture and port-scan), the probe first sends a processing message to the coordinator through the same topic to indicate that the command has started. Once the execution is completed, the probe creates a response containing the results obtained and publishes it to the #endpoint("probes/{probe_id}/response") topic. 
  
  Each command is implemented using librairies suited to its specific functionality. 

  === Ping
  The *ping* command is used to verify network connectivity between the probe and the DUT (Device Under Test). It uses the ICMP (Internet Control Message Protocol) to send Echo Request messages to a target address and wait for the corresponding Echo Reply messages.

  The ping command uses the #endpoint("prometheus-community/pro-bing") library@pro-bing to send ICMP echo requests and collect the corresponding results

  The parameters that must be provided to the probe to execute this command are the following:
  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface on which the ping is performed.],
      [target], [IP address or hostname of the target to ping.],
      [count], [Number of ICMP requests to send.],
      [timeout_ms],[Maximum time to wait for a response.],
    ),
    caption: [Ping execution parameters],
  ) <tbl:PingExec-parameters>

  #colbreak()

  The results of a *ping* executed successfully contain:
  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Results*],
        [*Description*],
      ),

      [packets_sent], [Number of ICMP packets sent.],
      [packets_received], [Number of ICMP packets received.],
      [PacketLossPercent],[Percentage of packets lost.],
      [rtt_min_ms],[Minimum round-trip time.],
      [rtt_avg_ms],[Average round-trip time.],
      [rtt_max_ms],[Maximum round-trip time.],
    ),
    caption: [Ping results],
  ) <tbl:Ping-Results>

  These values make it possible to evaluate not only the reachability of the target, but also the quality of the network connection.

  === Capture
  The *capture* command is used to record the traffic passing through a network interface for a defined period of time. The captured packets can then be analyzed to verify the behavior of the DUT, identify the protocols being used, or diagnose potential communication problems.

  The capture command uses the #endpoint("gopacket") library@gopacket and its #endpoint("pcap")@gopacket-pcap and #endpoint("pcapgo")@gopacket-pcapgo packages to capture network packets and handle PCAP files.

  The parameters that must be provided to the probe to execute this command are the following:

  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface on which the capture is performed.],
      [filter], [BPF filter applied during the capture.],
      [timeout_s], [Duration of the capture in seconds.],
    ),
    caption: [Capture execution parameters],
  ) <tbl:CaptureExec-parameters>
  
  The results of a *capture* executed successfully contain:
  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Results*],
        [*Description*],
      ),
      [pcap_b64], [Return a *pcap file* of the capture encoded in base64],
    ),
    caption: [Capture results],
  ) <tbl:Capture-Results>

  Returning a PCAP file is useful because it provides a convenient way to store network captures, by decoding the *pcap_b64* data and saving it as a file, and to compare captures obtained from different tests. Furthermore, this format is compatible with analysis tools such as Wireshark, allowing BPF filters to be applied afterwards to isolate only the relevant traffic from a complete network capture.

  === Port scan
  The *port-scan* command uses Nmap to identify the open ports on the DUT. It is used to determine which services are accessible on the device and to verify that only the expected ports are exposed on the network.

  The port scan command uses the #endpoint("Ullaakut/nmap") library@nmap-go to perform network port scans.

  The parameters that must be provided to the probe to execute this command are the following:

  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface used to perform the port scan.],
      [target], [IP address or hostname of the target to scan.],
      [ports], [Ports of the target to scan (example: 80,443,8000-8020,8080).],
      [sv], [Boolean value used to enable or disable the service detection.],
    ),
    caption: [Portscan execution parameters],
  ) <tbl:Portscan-parameters>

  The results of a *port scan* executed successfully contain:

  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Results*],
        [*Description*],
      ),

      [ports], [List of the scanned ports, including their ID, protocol, state (open/closed), and detected service.],
    ),
    caption: [Portscan results],
  ) <tbl:Portscan-Results>


  === HTTP request
  The *http* command uses Go's standard #endpoint("net/http") package@go-net-http to send HTTP requests. The #endpoint("encoding/base64") package@go-encoding-base64 is used to decode Base64-encoded request data, while #endpoint("unicode/utf8") package@go-unicode-utf8 is used to handle UTF-8 encoded data.

  The parameters that must be provided to the probe to execute this command are the following:

  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface used to perform the http request.],
      [method], [HTTP method used for the request, such as GET, POST or PUT.],
      [header], [HTTP headers to include in the request.],
      [url], [URL of the target HTTP resource.],
      [body], [Content of the HTTP request body. The body can contain JSON data, plain text, or Base64-encoded file content.],
    ),
    caption: [HTPP execution parameters],
  ) <tbl:HttpExec-parameters>
  
    #colbreak()

  The results of a *http* command executed successfully contain:
  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Results*],
        [*Description*],
      ),

      [status], [HTTP status code returned by the server.],
      [statusText], [Text associated with the returned HTTP status code.],
      [httpVersion], [HTTP version used for the response.],
      [headers], [HTTP headers returned by the server.],
      [content], [Content of the HTTP response body.],
    ),
    caption: [HTPP results],
  ) <tbl:Http-Results>

  === TCP request
  The *tcp* command uses Go's standard #endpoint("net") package@go-net-package to establish TCP connections and exchange data.

  The parameters that must be provided to the probe to execute this command are the following:
  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface used to perform the TCP request.],
      [source-port], [Source port used to establish the TCP connection.],
      [destination-ip], [IP address of the destination.],
      [destination-port], [Destination port to which the TCP connection is established.],
      [data], [Data sent to the destination.],
      [waiting-response], [Boolean value indicating whether the probe should wait for a response from the destination.],
    ),
    caption: [TCP execution parameters],
  ) <tbl:Tcp-parameters>

  The source IP address used for the TCP request is the IP address assigned to the network interface specified by the _interface_ parameter.
  
  The results of a *tcp* command executed successfully contain:
  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Results*],
        [*Description*],
      ),

      [response], [Data received from the destination. This field is empty if waiting-response is disabled.],
    ),
    caption: [TCP results],
  ) <tbl:Tcp-results>

  === TCP echo server
  The *tcp echo server* uses Go's standard #endpoint("net") package@go-net-package to create a TCP server that receives and sends back the received data. It was mainly implemented to test the TCP request command using two probes: one probe runs the TCP echo server, while the other sends TCP requests to it. The response received by the sending probe can then be compared with the original message to verify that the TCP communication and data exchange are working correctly.

  #colbreak()

  The parameters that must be provided to the probe to execute this command are the following:
  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface on which the TCP echo server listens for incoming connections.],
      [port], [TCP port on which the echo server listens for incoming connections.],
      [timeout_s], [Duration of the TCP echo server in seconds.],
    ),
    caption: [TCP echo server execution parameters],
  ) <tbl:TcpServer-parameters>

  The source IP address used for the TCP echo server is the IP address assigned to the network interface specified by the _interface_ parameter.
  
  The results of a *tcp echo server* command executed successfully contain:
  #figure(
    table(
      columns: (3fr, 8fr),
      align: left,

      table.header(
        [*Results*],
        [*Description*],
      ),

      [response], [List of the data received from the clients and sent back by the TCP echo server.],
    ),
    caption: [TCP echo server results],
  ) <tbl:TcpServ-Results>
  
  === UDP request
  The *udp* command uses Go's standard #endpoint("net")@go-net-package package to create UDP connections and send datagrams.

  The parameters that must be provided to the probe to execute this command are the following:
  #figure(
    table(
      columns: (2.5fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface used to perform the UDP request.],
      [source-port], [Source port used to establish the UDP connection.],
      [destination-ip], [IP address of the destination.],
      [destination-port], [Destination port to which the UDP connection is established.],
      [data], [Data sent to the destination.],
      [waiting-response], [Boolean value indicating whether the probe should wait for a response from the destination.],
    ),
    caption: [UDP execution parameters],
  ) <tbl:UdpExec-parameters>

  The source IP address used for the UDP request is the IP address assigned to the network interface specified by the _interface_ parameter.

  #colbreak()
  
  The results of a UDP request executed without errors contain:
  #figure(
    table(
      columns: (2.5fr, 8fr),
      align: left,

      table.header(
        [*Results*],
        [*Description*],
      ),

      [response], [Data received from the destination. This field is empty if waiting-response is disabled.],
    ),
    caption: [UDP results],
  ) <tbl:Udp-results>
  
  === UDP echo server
  The *udp echo server* uses Go's standard #endpoint("net") package@go-net-package to create a UDP server that receives and sends back the received data. It was mainly implemented to test the UDP request command using two probes: one probe runs the UDP echo server, while the other sends UDP requests to it. The response received by the sending probe can then be compared with the original message to verify that the UDP communication and data exchange are working correctly.

  The parameters that must be provided to the probe to execute this command are the following:
  #figure(
    table(
      columns: (2.5fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface on which the UDP echo server listens for incoming connections.],
      [port], [UDP port on which the echo server listens for incoming connections.],
      [timeout_s], [Duration of the UDP echo server in seconds.],
    ),
    caption: [UDP echo server execution parameters],
  ) <tbl:UdpServExec-parameters>

  The source IP address used for the UDP echo server is the IP address assigned to the network interface specified by the _interface_ parameter.
  
  The results of a UDP echo server request executed without errors contain:
  #figure(
    table(
      columns: (2.5fr, 8fr),
      align: left,

      table.header(
        [*Results*],
        [*Description*],
      ),

      [response], [List of the data received from the client and sent back by the UDP echo server.],
    ),
    caption: [UDP echo server results],
  ) <tbl:UdpServ-results>

  === Send pcap
  The *pcap* command sends the packets contained in a PCAP file through a selected network interface of the probe. It can be used to reproduce predefined network traffic and test how the DUT reacts to a specific sequence of packets.

  The PCAP sending command uses the #endpoint("pcap") package@gopacket-pcap from the #endpoint("gopacket") library@gopacket to send packets through a network interface. The #endpoint("encoding/base64") package@go-encoding-base64 is used to decode the PCAP file received from the coordinator.

  #colbreak()

  The parameters that must be provided to the probe to execute this command are the following:
  #figure(
    table(
      columns: (2.5fr, 8fr),
      align: left,

      table.header(
        [*Parameters*],
        [*Description*],
      ),

      [interface], [Network interface through which the packets from the PCAP file are sent.],
      [filter], [BPF filter used to select the packets to send from the PCAP file.],
      [file], [PCAP file containing the packets to be sent, encoded in Base64.],
    ),
    caption: [PCAP execution parameters],
  ) <tbl:PcapExec-parameters>
  
  The pcap command return no particular result, it sends a *success response message* with an empty result.
]
