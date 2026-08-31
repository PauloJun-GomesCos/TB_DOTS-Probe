#import "/metadata.typ": *

#let entry-list = (
  (
    key: "hei",
    short: "HEI",
    long: "School of Engineering",
    group: "University"
  ),
  (
    key: "synd",
    short: "SYND",
    long: "Systems Engineering",
    group: "University"
  ),
  (
    key: "it",
    short: "IT",
    long: "Infotronics",
    group: "University"
  ),
  (
    key: "ot",
    short: "OT",
    long: "Operational Technology",
    description: "Systems and technologies used to monitor and control physical processes in industrial environments.",
    group: "Concepts"
  ),
  (
    key: "dut",
    short: "DUT",
    long: "Device Under Test",
    description: "Device or system on which tests are performed to evaluate its behaviour and performance.",
    group: "Testing"
  ),
  (
    key: "iot",
    short: "IoT",
    long: "Internet of Things",
    description: "Network of physical devices capable of collecting, exchanging, and processing data.",
    group: "Concepts"
  ),

  (
    key: "mqtt",
    short: "MQTT",
    long: "Message Queuing Telemetry Transport",
    description: "Lightweight publish-subscribe messaging protocol used for communication between the probes and the coordinator.",
    group: "Protocols"
  ),
  (
    key: "http",
    short: "HTTP",
    long: "HyperText Transfer Protocol",
    description: "Application-layer protocol used to transfer data between clients and web servers.",
    group: "Protocols"
  ),
  (
    key: "tcp",
    short: "TCP",
    long: "Transmission Control Protocol",
    description: "Connection-oriented transport protocol that provides reliable and ordered delivery of data.",
    group: "Protocols"
  ),
  (
    key: "udp",
    short: "UDP",
    long: "User Datagram Protocol",
    description: "Connectionless transport protocol that provides low-overhead data transmission without guaranteeing delivery.",
    group: "Protocols"
  ),
  (
    key: "icmp",
    short: "ICMP",
    long: "Internet Control Message Protocol",
    description: "Network-layer protocol used for control messages and diagnostic operations such as ping.",
    group: "Protocols"
  ),
  (
    key: "dhcp",
    short: "DHCP",
    long: "Dynamic Host Configuration Protocol",
    description: "Protocol used to automatically assign network configuration parameters such as IP addresses to devices.",
    group: "Protocols"
  ),
  (
    key: "dns",
    short: "DNS",
    long: "Domain Name System",
    description: "System used to resolve domain names into IP addresses.",
    group: "Protocols"
  ),

  (
    key: "ip",
    short: "IP",
    long: "Internet Protocol",
    description: "Network-layer protocol responsible for addressing and routing packets between networked devices.",
    group: "Networking"
  ),
  (
    key: "bpf",
    short: "BPF",
    long: "Berkeley Packet Filter",
    description: "Packet filtering mechanism used to select network traffic matching specific criteria.",
    group: "Networking"
  ),
  (
    key: "pcap",
    short: "PCAP",
    long: "Packet Capture",
    description: "File format and mechanism used to store captured network packets for later analysis.",
    group: "Networking"
  ),

  (
    key: "json",
    short: "JSON",
    long: "JavaScript Object Notation",
    description: "Lightweight text-based format used to represent and exchange structured data.",
    group: "Data Formats"
  ),
  (
    key: "lwt",
    short: "LWT",
    long: "Last Will and Testament",
    description: "MQTT mechanism that allows a message to be published when a client unexpectedly disconnects.",
    group: "MQTT"
  ),
)

#let make_glossary(
  gloss:true,
  title: i18n("gloss-title", lang: option.lang),
) = {[
  #if gloss == true {[
    #pagebreak()
    #set heading(numbering: none)
    = #title <sec:glossary>
    #print-glossary(
      entry-list,
      // show all term even if they are not referenced, default to true
      show-all: true,
      // disable the back ref at the end of the descriptions
      disable-back-references: false,
    )
  ]} else{[
    #set text(size: 0pt)
    #title <sec:glossary>
    #print-glossary(
      entry-list,
      // show all term even if they are not referenced, default to true
      show-all: false,
      // disable the back ref at the end of the descriptions
      disable-back-references: false,
    )
  ]}
]}
