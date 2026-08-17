# Distributed OT Test Suite – Probe

This repository contains the work developed as part of a Bachelor's thesis focused on the development of a **distributed probe for testing Operational Technology (OT) environments**.

The probe is a configurable and remotely controlled device capable of performing various network tests, including connectivity tests, traffic capture and transfer, port scanning, HTTP requests, and TCP and UDP communications.

The probe is designed to operate in two distinct environments: a known **configuration environment** and a potentially changing **test environment**. This separation provides the probe with a known reference environment from which it can be configured to adapt to different test networks.

It supports different network configurations, including static and dynamic IP addressing of its interfaces, as well as a transparent bridge mode. Using the **MQTT protocol**, the probe communicates with a coordinator to receive commands and configuration parameters, execute the requested tests, and return their results.

The probe also provides the coordinator with the definitions of its available commands and configuration parameters, together with the metadata required to dynamically generate the coordinator's web interface. This approach allows new functionalities to be added to the probe without requiring modifications to the coordinator, making the architecture more flexible and extensible.

## Repository Structure

The repository is divided into three main directories:

```text
.
├── Code/
├── Documentation/
├── Report/
└── Functional-Test/
```

### Code

The `Code/` directory contains the complete source code of the probe.

The probe is implemented in **Go** and includes the components responsible for:

* MQTT communication with the coordinator.
* Network configuration and interface management.
* Probe discovery and status reporting.
* Command execution.
* Configuration management.
* Capability and configuration parameters metadata generation.

The implemented network capabilities include the following commands:
* Ping
* Packet capture
* Port scanning
* HTTP requests
* UDP data sending
* UDP echo server
* TCP data sending
* TCP echo server
* PCAP sending 

### Documentation

The `Documentation/` directory contains contains additional technical documentation
for developers and users of the probe.

It includes:
- A guide that explains how to extend the probe. It explains how to add a new capability, configuration group, or configuration parameter while ensuring that the required metadata is included in the announce message and can therefore be displayed correctly in the coordinator web interface.

### Report

The `Report/` directory contains the Bachelor's thesis report.

The Report/ directory contains the Bachelor's thesis report. It presents the project context and objectives, the sustainability considerations, the analysis and selection of the probe hardware, the system design and architecture, the implementation of the probe and its communication with the coordinator, its deployment and network configuration, as well as the implemented network capabilities. The report also presents a proof of concept, the functional and performance validation performed on the test bench, and a discussion of the results, limitations, and future perspectives.

### Functional Tests

The `Functional-Test/` directory contains the test suites used for the functional tests performed on the test bench.

The test suites are provided as JSON files exported from the coordinator's web interface. They contain the test configurations and can be imported back into the coordinator, adapted to the target network configuration, and executed again. This allows the functional tests performed during the project to be reproduced on a different test environment.

These test suites were used to validate the behaviour of the probe in a distributed OT environment and to verify the implemented commands, network configurations, and MQTT communication.

The test bench used during the project included three probes and one Device Under Test (DUT).