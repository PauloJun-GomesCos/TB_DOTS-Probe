#import "../metadata.typ": *

#import "/resources/diagram/fit.typ": fit
#import "/resources/diagram/System-content.typ": (
  system, system-size
)
#import "/resources/diagram/Project-Architecture-content.typ": (
  system-overview, system-overview-size
)

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

#pagebreak()
= #i18n("design-title", lang:option.lang) <sec:design>

This chapter presents the design of the probe and the system in which it is intended to operate. It first describes the two network environments considered for the deployment of the probe, as well as the requirements that the probe must fulfil. The software architecture of the probe is then presented, followed by a description of its workflow. The main libraries used to implement the proposed architecture are subsequently introduced. Finally, the communication interface between the probe and the coordinator is described, along with the deployment architecture used to run the probe.

#option-style(type:option.type)[
  In the design section of your bachelor thesis, you have the opportunity to provide a detailed blueprint of the system you intend to develop or analyze. This section serves as the foundation upon which your implementation will be built. Here's how you can enrich and expand upon this section:

  - *System Overview*: Begin by providing a comprehensive overview of the system under consideration.
  - *Requirements Specification*: Outline the specific requirements that your system must fulfill.
  - *Architecture and Design Principles*: Delve into the architectural design of your system, elucidating the underlying principles and design decisions that govern its structure.
  - *Technology Stack*: Detail the technologies and tools that will be employed in the development of your system.
  - *Data Management and Storage*: If your system involves the management or manipulation of data, provide insights into how data will be structured, stored, and accessed.
  - * User Interface (UI) Design*: If applicable, describe the user interface of your system, focusing on usability, accessibility, and user experience (UX) design principles.
  - *Integration and Interoperability*: Address how your system will integrate with existing systems or external services, if relevant.
]


#add-chapter(
  after: <sec:design>,
  before: <sec:impl>,
  minitoc-title: i18n("toc-title", lang: option.lang)
)[
  #pagebreak()
  == Overview of the dual-environement system
  The system designed for the deployment of the probes is divided into two separate environments: a *configuration environment* and a *test environment*. These environments are completely isolated from each other, and each has its own coordinator and MQTT broker. This separation makes it possible to prepare and configure the probes before deploying them in the OT network where the DUT (Device Under Test) will be tested.

  The following diagram illustrates the overall architecture of the configuration and test environments, including the probes, MQTT brokers, coordinators, and the different networks involved.
  #figure(
    fit(system-size.w - 5cm, system-size.h - 6.5cm, system()),
    caption: [Diagram of the dual-environement system],
  ) <sys-overview>

  The *configuration environment* is a permanent and controlled environment with a DHCP server and access to the Internet. It is used to *prepare and configure* the probes before their deployment in a test environment. Its MQTT broker is also permanent, meaning that its address and configuration are normally unchanged and always known to the probes. The informations required to connect to this MQTT broker are defined in a #endpoint(".env") file. This environment provides the probe with a reliable network from which it can initially connect to the coordinator and receive the parameters required for deployment. These parameters can include the static IP addresses and MQTT credentials needed to operate in the target test environment. This allows the probe to be prepared before deployment in a network that may not provide DHCP, Internet access, or other network configuration services.

  The *test environment* represents the actual OT network in which the probe will be deployed. Its configuration can vary significantly, and it may not provide services such as DHCP. Configuring the probe beforehand in a known and controlled environment is therefore essential. Once deployed in the OT network, the probe can operate using its pre-configured parameters without requiring any changes to the existing network infrastructure. However, the probe's configuration can also be modified remotely while it is deployed in the test environment, allowing its network parameters and other configuration settings to be adapted to the specific requirements of the tests being performed.

  The example shown in the diagram illustrates how a probe is prepared before being deployed in a test environment. Initially, the two probes are connected to the configuration environment, where a DHCP server assigns an IP adress to their *eth0* interfaces (#endpoint("192.168.38.175") and #endpoint("192.168.38.176")). These addresses allow the probes to establish communication with the Config Coordinator and receive their configuration. One of the probes is configured to operate as a bridge between its test interfaces. The probes are then configured with their specific test environement parameters, it's include *static IP* addresse for the interfaces *eth0*, *eth1*, *eth2* and the *bridge*, as well as the *MQTT credentials* required to connect to the Test Broker. They therefore have both DHCP-assigned address and a static IP address on *eth0*, while connected in the configuration environement. Once configured, the probes are moved to the test environment and connected to the OT network. They use the network parameters configured during the *configuration phase*, including their static IP addresses and MQTT credentials, to establish communication with the *Test Broker*. The IP address previously assigned by DHCP in the configuration environment is no longer used, and only the pre-configured static IP address remains active on the coordination interface. The probes can therefore operate in the test environment without requiring additional configuration of the OT network, allowing them to receive commands from the Test Coordinator and execute the required tests on the DUT.

  == Requirements Specification
  The probe must provide a set of core functionalities required for its integration into the environment. It must first be able to register with the coordinator and report the capabilities it supports. In addition, the probe must expose the configuration parameters that can be modified remotely and apply any configuration changes received from the coordinator. These configuration settings must be saved locally so that they are retained across probe restarts.

  The probe must also support the execution of commands requested by the coordinator. It must receive commands, execute the corresponding tests, return their results, and maintain a local log of the operations performed.

  To support the dynamic integration of capabilities, each command exposed by the probe must provide its complete definition. This definition contains both the *information required to invoke the command*, such as its name and execution parameters, and the *metadata required to represent it in the coordinator's web interface*. The same principle applies to the probe configuration. For each configurable parameter, the probe provides the information required by the coordinator to display and modify it. This approach allows the coordinator to *dynamically* construct its user interface based on the information provided by the probe. As a result, new commands or configuration parameters can be integrated without modifying the coordinator's underlying logic, *simplifying* the addition and integration of new probe functionalities.

  The probe must also provide flexible network configuration capabilities. The two interfaces dedicated to the test network (*eth1* and *eth2*) must be capable of operating as a *bridge*. This allows the probe to be placed beetween two network devices and transparently forward the traffic between them while capturing it, without interrupting the connection.

  All probe network interfaces must support both *static and dynamic IP* address configuration. This allows the probe to adapt to the different network configurations encountered in the test environments.

  Finally, the architecture based on two seperate environements introduces additional network requirements. Since the configuration process differs between the configuration and test environments, the probe must be able to determine which MQTT broker is reachable through its coordination interface and dynamically apply the configuration associated with that environment.

  #pagebreak()

  == Architecture of the probe
  The probe software is organized into several packages, each responsible for a specific part of its functionality. This modular architecture separates the different responsibilities of the application while allowing the components to interact with each other. The following section presents the overall architecture of the probe, from its main components to the internal structure of the #endpoint("probe") package.

  The following diagram shows the main packages of the probe and the relationships between them. It illustrates how the probe package interacts with the supporting packages to provide the required functionality.
  
  #figure(
    fit(system-overview-size.w - 3.5cm, system-overview-size.h, system-overview()),
    caption: [Architecture of the probe],
  ) <probe-architecture>

  The architecture shown in the diagram is composed of four main packages: #endpoint("mqttclient"), #endpoint("network"), #endpoint("models"), and #endpoint("probe"). The #endpoint("probe") package contains the main execution logic of the application and is further divided into several sub-packages. These sub-packages are #endpoint("probe.probe"), #endpoint("probe.services"), #endpoint("probe.status"), #endpoint("probe.capabilities") and #endpoint("probe.config"). Therefore, these five components are part of the probe package and are shown to illustrate its internal structure and the relationships between its components.
  
  #colbreak()

  The main responsibilities of the four main packages are summarized in the following table.
  #figure(
    table(
      columns: (2fr, 8fr),
      align: left,

      table.header(
        [*Package*],
        [*Responsability*],
      ),

      [*mqttclient*], [This package implements the MQTT client used to communicate with the MQTT broker. It provides functions to create, configure and reconfigure the client, connect to a broker, subscribe or resubscribe to topics, and publish messages. It also generates events when the client connects, disconnects, or fails to connect to a broker.],
      [*network*], [This package handles the probe's network interfaces. It provides functions to retrieve and modify IP addresses, create network bridges, and perform other network-related operations required by the probe.],
      [*models*], [This package defines the data structures used for all MQTT messages exchanged by the probe. These structures ensure that messages are consistently formatted throughout the application.],
      [*probe*], [The probe package contains the main execution logic and relies on the #endpoint("mqttclient"), #endpoint("network"), and #endpoint("models") packages to perform its operations.],
    ),
    caption: [Responsability of the main packages of the probe],
  ) <tbl:probe-main-packages>

  The probe package is further divided into several *sub-packages*, each dedicated to a specific functionality of the probe. This organization separates the different responsibilities of the application and makes the code easier to maintain and extend. The following table presents these sub-packages and their respective responsability.

  #figure(
    table(
      columns: (2fr, 8fr),
      align: left,

      table.header(
        [*Package*],
        [*Responsability*],
      ),

      [*probe*],[Contains the core logic of the probe, including its configuration, state, and main operations. It also defines the callback functions (#endpoint("HandleCommand"), #endpoint("HandleControl") and #endpoint("HandleDiscover")) used to handle messages received on the MQTT topics to which the probe is subscribed.],
      [*services*], [Contains the implementations of the different command supported by the probe, such as ping, capture, portscan, HTTP request, TCP/UDP message and pcap execution.],
      [*status*], [Handles the periodic sending of status messages to report the current state of the probe.],
      [*capabilities*], [Contains the definitions of all commands supported by the probe. These definitions specify the parameters required to execute each action, as well as metadata used to display the commands in the coordinator's web interface.],
      [*config*], [Handles the probe configuration parameters as well as their persistence in a JSON configuration file.],
    ),
    caption: [Responsability of the internal packages of the probe package],
  ) <tbl:probe-internal-packages>

  #colbreak()

  The workflow of the probe is as follows. During startup, the probe is created and loads its configuration from the JSON configuration file (#endpoint("probe.config") package). It then searches for an available MQTT broker on its *coordination network*, which can be either the configuration broker or the test broker. As soon as a broker is detected, the MQTT client is configured with the parameters corresponding to that broker, and a connection is established.

  Once the connection is established, the probe *subscribes* to the required topics and associates a specific *callback function* to them. Each callback is responsible for processing the received message and triggering the corresponding action. This architecture allows the probe to process messages asynchronously.

  When the connection to the broker and all topic subscriptions have been established, the probe announces itself to the coordinator by sending its *list of capabilities* and its *list of configuration parameters*. The capabilities and configuration parameters of this lists contains the *metadata* required by the coordinator to display and dynamically manage its interface. The probe then waits to receive messages from the coordinator. When a message is received, the callback associated with the corresponding topic is executed to process the message and trigger the appropriate action.

  If the probe *loses its connection* to the MQTT broker, it enters a *reconnection* state and continuously searches for an available broker on its coordination network. When a broker is detected, the MQTT client is *reconfigured* with the parameters corresponding to that broker, and it *resubscribe* to the topics. This process allows the probe to switch between environments and automatically adapt its configuration to the broker it connects to. Once the connection has been re-established, the probe reannounce itself and waits for messages from the coordinator.

  == Librairies used
  The implementation of the probe relies on several external libraries, each providing specific functionality. The following table presents these libraries, the packages that use them, and a brief description of their purpose.
  
  #figure(
    table(
      columns: (2fr, 2fr, 6.5fr),
      align: left,

      table.header(
        [*Library*],
        [*Package*],
        [*Description*]
      ),

      [*paho mqtt* @paho-mqtt],[#endpoint("mqttclient")],[The paho mqtt librrary provides MQTT client functionalities for connecting to a MQTT broker, subscribing to topics and publishing messages.],
      [*netlink* @netlink],[#endpoint("network")], [The netlink library provides a simple netlink library for go. It give access to features such as managing interfaces, IP addresses, and network bridges.],
    ),
    caption: [Libraries used in the probe],
  ) <tbl:probe-libraries>

  The libraries used for the implementation of each probe command, such as ping, packet capture, or port scanning, are mentioned in the dedicated sections of the implementation chapter.

  == Interface with the coordinator
  The communication between the coordinator and the network probes is entirely based on *MQTT topics*. These topics define the interface of the system, allowing both *command delivery* and *result collection* in a structured and scalable way.

  The topic hierarchy follows a consistent naming convention, where each probe is identified by a unique identifier. This ensures that messages are properly routed to the intended recipient without ambiguity.

  The topics hierarchy used in the system is as follows:

  #box(
    fill: rgb("#f5f5f5"),
    stroke: rgb("#d0d0d0"),
    inset: 1em,
    radius: 2pt,
    width: 100%,
  )[
    - `probes/announce`
    - `probes/discover` 
    - `probes/{probe_id}/status`         
    - `probes/{probe_id}/control`    
    - `probes/{probe_id}/command`    
    - `probes/{probe_id}/response`
  ]

  The following subsections describe each MQTT topic and its role within the system. All messages exchanged through these topics use the *JSON format* and contains a *timestamp* indicating the time of sending. For each topic, an explanation of the message structure is provided along with a real example.

  === probes/announce
  This topic is used by all probes to *announce* their presence to the coordinator. The *announcement messages* allow the coordinator to identify available probes, retrieve their current configuration, and discover the actions they can perform.

  A probe publishes an *announcement message* when it starts up, in response to a discovery request received on the #endpoint("probes/discover") topic, and after any configuration update performed through the #endpoint("probes/{probe_id}/control") topic. This ensures that the coordinator always has an up-to-date view of each probe.

  The *announcement message* contains general information about the probe, including its identifier, firmware version, network information (IP addresses and MAC addresses of all available interfaces), supported capabilities with their parameters, the configuration groups and the current configuration values.

  Here is a excerpt from a *announcement message* :
  ```json
  {
    "probe_id": "probe-05e4fa",
    "request_id": null,
    "type": ["ethernet"],
    "firmware_version" : "1.0.0",
    "capabilities" : [
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
      {
        ...
      }
    ],
    "config_groups": [
      {"key": "network", "label": "Network", "icon": "lan"},
      {"key": "mqtt", "label": "MQTT credentials", "icon": "hub"},
      ...
    ],
    "config" : [
      {"key" : "name", "label" : "Name", "type" : "string", "value" : "Probe LAN"},
      {"key" : "status_interval_s", "label" : "Status interval", "type" : "number", "value" : "1"},
      ...
    ],
    "network": {
      "eth0": {
        "ip": [
          "192.168.38.183/22",
          "10.0.0.82/24"
        ],
        "mac": "fe:b6:53:86:ba:87"
      },
      ...
    },
  }
  ```

  === probes/discover
  This topic is used by the coordinator to *request* all connected probes *to announce* themselves again. When a probe receives a message on this topic, it responds by publishing an *announcement message* on the #endpoint("probes/announce") topic.

  The *discovery message* contains only a _request_id_ field, which uniquely identifies the request. This identifier is included in the corresponding *announcement message*, allowing the coordinator to associate each response with the original discovery request.

  ==== probes/{probe_id}/status
  This topic is used by each probe to *periodically* inform the coordinator that it is still online. The publication interval is configurable through the probe configuration parameters. 

  The *status message* contains some information about the probe, including its name, state (online or disabled), uptime, CPU and memory usage, as well as temperature. In case of unexpected disconnection, the MQTT *LWT* (Last Will Testament) mecahnism is used to automatically publish an offline *status message*, allowing the coordinator to be informed about a probe disconnection 
  
  Here is an *status message* example :
  ```json
  {
    "name": "Probe LAN",
    "state": "online",
    "uptime_seconds": 4128,
    "cpu_percent": 0.5050505050473733,
    "memory_percent": 4.2865128805403625,
    "timestamp": 1781256880393,
  }
  ```
  The offline *status message* send by the MQTT LWT only contains the field state, whose value is set to offline.

  === probes/{probe_id}/control 
  This topic is used by the coordinator to *configure* a specific probe. 

  The *configuration message* contains a unique ID to distinguish each configuration request and a list of parameters whith the value to be applied. The available configuration are defined by the name contained in the _key_ field from the configuration list provided by the probe in it's *announcement message*.

  Here is a excerpt from a *configuration message* :
  ```json
  {
    "id": "setup-1783320613529525977",
    "params": {
      "name": "Probe LAN",
      "status_interval_s": 30,
      "enabled": true,
      "bridge_mode": false,
      ...
    }
  }
  ```
  
  #colbreak()

  === probes/{probe_id}/command
  This topic is used by the coordinator to send a *command* request to a specific probe.

  The *command message* contains a unique ID to distinguish each command request, the name of the action to execute and a list of parameters required for its execution. The list of parameters for each action is defined in the _params_ field of the corresponding capability description, provided in the _capabilities_ field of the *announcement message*. 

  Here is an example of *command message* :
  ```json
  {
    "id": "2d5de829-ccdb-404d-91f8-be0835a795b2",
    "action": "ping",
    "params": {
      "interface": "eth0",
      "target": "192.168.3.10",
      "count": 4,
      "timeout": 1000
    }
  }
  ```

  === probes/{probe_id}/response
  This topic is used by a specific probe to *answer* a configuration request (#endpoint("probes/{probe_id}/control")) or a command request (#endpoint("probes/{probe_id}/command")).

  The *response message* contains the identifier of the request to wich it coressponds, a status field (success, error, processing), an error that follows a generic format composed of an error code and an error message, and a result field. When the response message is associated with a *configuration request*, the _result_ field is always empty. When it's sent in response to a *command request*, the format of the _result_ field depends on the executed action. The list of results expected for each action is defined in the _result_ field of the corresponding capability description, provided in the _capabilities_ field of the *announcement message*. 

  Here is an example of *response message* with no errors :

  ```json
  {
    "id": "2d5de829-ccdb-404d-91f8-be0835a795b2",
    "status": "success",
    "error": {
      "code": 0,
      "message": ""
    },
    "result": {
      "packets_sent": 4,
      "packets_received": 4,
      "packet_loss_percent": 0,
      "rtt_min_ms": 1.063101,
      "rtt_avg_ms": 1.157672,
      "rtt_max_ms": 1.209514
    },
  }
  ```
  
  == Deployement
  The probe software is deployed as a Docker container on the NanoPi R5S. Docker allows the application and its required dependencies to be packaged together, making the deployment process consistent between different probes.

  The *Dockerfile* defines how the probe application is built and packaged into a Docker image. It uses a *multi-stage build* with three stages. The #endpoint("deps") stage provides the Go environment and installs the dependencies required to compile the application. The second stage, named #endpoint("build"), inherits the environment from the #endpoint("deps") stage. The source code is copied into the container and the probe is compiled into a single executable binary named #endpoint("probeBin").
  Finally, the #endpoint("probe") stage uses a lightweight Debian image (#endpoint("debian:bookworm-slim")) and installs only the dependencies required by the probe. The compiled binary is then copied from the #endpoint("build") stage into the final image and configured as the container's entry point. This approach keeps the final image lightweight by excluding the Go compiler and other build dependencies.

  The Docker image is published to the *GitHub registry* (ghcr.io) and can then be pulled by the NanoPi during deployment. Docker Compose is used to start and configure the probe container. The deployment also requires a #endpoint(".env") file containing the configuration parameters specific to the environment. These parameters are documented in the #endpoint(".env.example") file and include the MQTT credentials, as well as the path to the JSON file used to store the probe configuration. This #endpoint(".env") file is provided separately from the Docker image.
   
  The Docker Compose configuration defines how the container is started and provides the required network configuration, environment variables, and permissions. In particular, the container uses the host network mode (#endpoint("networ_mode: host")) to access the NanoPi's network interfaces directly, which is required for the probe's network operations and bridge configuration. The container is also granted the necessary privileges (#endpoint("privileged: true")) to perform these low-level network operations.

  The deployment process consists of building the Docker image for the ARM64 architecture using #endpoint("docker compose build"), publishing it to the container registry using #endpoint("docker compose push"). On each NanoPi, the image is then retrieved with #endpoint("docker compose pull") and started using #endpoint("docker compose up -d"), together with the appropriate #endpoint(".env") file. This approach allows the same Docker image to be reused on multiple probes while keeping environment-specific configuration separate from the application.

  The #endpoint("Dockerfile"), #endpoint("docker-compose.yml"), and #endpoint(".env.example") file used for the deployment are provided in the appendices of this report.
]
