#import "../metadata.typ": *
#pagebreak()
= #i18n("conclusion-title", lang:option.lang) <sec:conclusion>

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
  In the concluding section of your bachelor's thesis, you consolidate the essence of your research journey, encapsulating the most pivotal insights garnered throughout your study. Here's how to enhance and structure your conclusion:

  - *Project Summary*: Offer a succinct recapitulation of the core elements of your project, including its objectives, methodologies employed, and the main findings obtained.
  - *Comparison with Initial Objectives*: Reflect upon how your research outcomes align with the initial objectives set forth at the outset of your thesis.
  - *Encountered Difficulties*: Acknowledge and address any challenges or obstacles encountered during the course of your research.
  - *Future Perspectives*: Offer insights into potential avenues for future research or practical applications stemming from your findings.

  While you keep the conclusion of your bachelor thesis short and to the point, you deal with your results in more details in the discussion. There is no new informations in the conclusion.
]

== Project summary
During this Bachelor's thesis, an embedded probe was designed and implemented to perform network tests in OT environments. The probe communicates with a coordinator through MQTT, receives the commands to be executed, performs the requested operations, and returns their results. It supports several types of network tests, including ICMP connectivity tests, TCP and UDP communications, HTTP requests, port scans, network traffic capture, and PCAP file replay.

The probe is remotely configurable, allowing its network interfaces and operating parameters to be adapted to different test environments. The configured parameters are saved locally in a configuration file, ensuring that they are preserved after a restart. The probe was also designed to operate in two distinct environments: a configuration environment and a test environment. This allows it to be prepared in a knwon environment before deployment and used in different network configurations without requiring extensive manual configuration in the OT environment.

The probe's operation was validated through various functional tests performed in a dedicated test bench, allowing its different functionalities to be verified in a representative environment. Performance tests were also conducted to evaluate its behavior when executing multiple operations in parallel and to identify its limits in terms of resource usage and execution time.

== Comparison with the initial objectives
All requirements defined in Section 4.2 were successfully met. The probe can register with the coordinator and provide a complete list of its available commands and configuration parameters, together with the metadata required to display them in the web interface. Configuration parameters can be remotely modified by the coordinator and are stored persistently, allowing them to be preserved after a probe restart. The probe can also receive commands, execute the corresponding operations, and return their results to the coordinator. Execution logs are displayed directly in the terminal, providing visibility into the probe's activity and the commands being executed.

The probe can also identify the environment in which it is operating and automatically connect to the corresponding MQTT broker. Its network interfaces can be configured according to the requirements of the test environment, using either static or dynamically assigned IP addresses. In addition, the two interfaces dedicated to the test network can be configured in bridge mode, allowing the probe to be placed between two devices while transparently forwarding their network traffic.

== Encountered difficulties
One of the difficulties encountered was that when a static IP address was assigned to an interface that had previously obtained an address through DHCP, the existing DHCP address remained active instead of being replaced. As a result, the interface had two IP addresses simultaneously: one assigned by DHCP and the other configured statically. This behavior was caused by the OS DHCP client, which continued running in the background and automatically assigned an address to the interface. The difficulty came from the fact that the probe runs inside a Docker container, while the DHCP client belongs to the host OS, making it difficult to control it directly from the container. After several investigations, nsenter was identified as a solution, as it allows commands to be executed within the namespaces of another process, including its network namespace. This made it possible for the probe to execute the DHCP desactivation command within the host's network namespace and correctly disable the DHCP client on the targeted interface.

I also encountered difficulties related to DNS configuration, as described in Section 5.6.3.

Another difficulty was related to the management of the two MQTT brokers used in the different environments. The probe had to be able to dynamically reconfigure its MQTT client depending on which broker was available. Implementing this mechanism required several adjustments to the MQTT client to ensure that the connection could be reliably established, interrupted, and restored when switching between environments.

== Future perspectives
Several improvements could be considered for future versions of the probe:

- *Extended network configuration*: The current network configuration could be expanded with additional options to provide greater flexibility when adapting the probe to different test environments. For example, gateway configuration could be added to allow each interface to use a specific gateway when required. Another possible improvement would be to support the configuration of a specific DNS server for each interface. The #endpoint("net.Resolver") implementation developed during the proof of concept could be further integrated for this purpose, allowing DNS requests to be performed through the appropriate network interface and DNS server. This would make the probe better suited to test environments with different network configurations and routing requirements.

- *PCAP file transfer in multiple parts*: As shown by the limitation tests, the size of a PCAP capture that can be transferred via MQTT is limited. Consequently, captures exceeding this limit cannot currently be sent to the coordinator. A possible improvement would be to split the PCAP file into smaller parts and transmit them separately. This would allow larger captures to be transferred and retrieved while remaining within the limitations of the MQTT protocol.

- *Additional test capabilities*: Another possible improvement would be to add new types of tests to make the probe more complete and increase the range of operations it can perform. This would allow the probe to cover more testing scenarios and evaluate a wider range of network and system properties in OT environments.