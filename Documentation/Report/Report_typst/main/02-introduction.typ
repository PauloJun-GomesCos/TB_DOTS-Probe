  #import "../metadata.typ": *
#pagebreak()
= #i18n("introduction-title", lang:option.lang) <sec:intro>

== Context Problem
OT environments play a critical role in the industry, as they are responsible for controlling and monitoring critical processes. OT systems interact directly with the physical world and are therefore subject to strict security and reliability requirements.

To ensure the proper operation of these systems, numerous functional and security tests must be carried out. These tests need to be defined, executed in a repeatable manner, and documented whenever the system is modified. However, implementing such tests remains a complex task. It often requires manual intervention on different network devices, as well as the observation of the effects produced at multiple points within the installation. This approach is time-consuming, difficult to reproduce, and increases the risk of human error.

To resolve this issue, the Distributed OT Test Suite project proposes an architecture designed to automate test campaigns. This architecture relies on a central coordination system responsible for planning and orchestrating test scenarios, as well as probes deployed directly within the OT environment. These probes execute the test commands asked by the coordinator, perform various test operations, and return the results obtained.

== Objectives
The objective of this Bachelor’s thesis is to develop a probe that can be deployed within an OT environment to perform distributed test operations. The probe must be capable of:

- Registering itself with a coordinator, allowing the system to identify and manage the different probes deployed within the OT environment.
- Announcing the list of capabilities it implements, enabling the coordinator to determine which test operations can be performed by each probe.
- Providing the coordinator with a list of its configurable parameters, allowing its network and operational configuration to be modified remotely according to the requirements of the test environment. These configuration changes must be stored locally so that they are preserved across restarts.
- Receiving and executing commands sent by the coordinator, then transmitting the results of the executed tests back to the coordinator.
- Maintaining a local log of the commands executed by the probe.

== Structure of this report
This report is structured into several sections covering the different stages of the thesis. First, the Analysis presents the evaluation of the different hardware options considered for the probe. The Design section then describes the dual environments in which the probe is deployed, its overall architecture, and its communication with the coordinator. The Implementation section details the development of the different components required to meet the defined requirements. A Proof of Concept section presents an additional feature that could potentially be integrated into the system in the future. The Validation section evaluates the developed solution through tests performed on a physical test bench. Finally, the Conclusion summarizes the work and discusses the main results and possible future improvements.
