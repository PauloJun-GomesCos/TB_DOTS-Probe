#import "../metadata.typ": *
#pagebreak()
#heading(numbering:none)[#i18n("abstract-title", lang:option.lang)] <sec:abstract>

#option-style(type:option.type)[
  The abstract serves as a concise summary of your entire thesis, encapsulating key elements on a single page such as:
  - General background information
  - Objective(s)
  - Approach and method
  - Conclusions
]

Operational Technology (OT) environments require numerous functional and security tests to ensure their proper operation. These tests must be defined, repeated, and recorded whenever the system is modified to ensure traceability. However, preparing the test environment and conducting these tests is a complex procedure, as different operations must be performed at multiple points of the infrastructure and their effects must be observed. This work therefore focuses on the development of distributed probes that enable these test operations to be performed.

This Bachelor's thesis presents the development of a distributed probe designed to test OT environments. The probe is a configurable and remotely controlled device capable of performing various network tests, including connectivity tests, traffic capture and transfer, port scanning, HTTP requests, and TCP and UDP communications.

The probe was designed to operate in two distinct environments: a known configuration environment and a potentially changing test environment. This separation provides the probe with a known reference environment from which it can be configured to adapt to different test networks.

It supports different network configurations, including static and dynamic IP addressing of his interfaces as well as transparent bridge mode. Using the MQTT protocol, it communicates with a coordinator to receive commands and configuration parameters, execute the requested tests, and return their results.

Finally, the probe provides the coordinator with the definitions of its commands and configuration parameters, together with all the metadata required to dynamically generate the coordinator's interface. This approach allows new functionalities to be added to the probe without requiring modifications to the coordinator, making the architecture more flexible and extensible.

The probe was tested on a test bench containing three probes and one DUT (Device Under Test) to evaluate its various functionalities, performance and interporpapility with the DOTS coordinator.

#v(2em)
#if doc.at("keywords", default:none) != none {[

  _*#i18n("keywords", lang: option.lang)*_:

  #enumerating-items(
    items: doc.keywords,
    italic: true
  )
]}
