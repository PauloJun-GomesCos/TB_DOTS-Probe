#import "/resources/diagram/fit.typ": fit
#import "/resources/diagram/Project-Architecture-content.typ": (
  system-overview, system-overview-size
)
#import "/resources/diagram/banctest-content.typ": (
  banctest, banctest-size,
)

#let navy = rgb("#043067")
#let blue = rgb("#0f63bf")
#let skyblue = rgb("#2e9bff")
#let lightblue = rgb("#4fc1ff")
#let panelalt = rgb("#eef3fa")
#let white = rgb("#ffffff")
#let black = rgb("#000000")
#let darknavy = rgb("#021a3b")

#set page(
  width: 594mm,
  height: 841mm,
  margin: (
    top: 20mm,
    bottom: 40mm,
    left: 20mm,
    right: 20mm,
  ),
  fill: white,
  bleed: 5mm,
  footer: [
    #box(
      width: 100%,
      height: 35mm,
    )[
      #grid(
        columns: (1fr, 2fr, 1fr),
        align: (left, center, right),

        image(
          "../resources/img/logos/hevs-pictogram.svg",
          width: 60mm,
        ),

        align(
          bottom,
          text(
            size: 20pt,
            fill: darknavy,
          )[
            School of Engineering - www.hevs.ch/hei - hei\@hevs.ch
          ]
        ),

        image(
          "../resources/img/logos/swiss_universities-valais-excellence-logo.svg",
          width: 65mm,
        ),
      )
    ]
  ]
)

#let round_height = 8mm
#let marg = 6mm

#let title-box(title) = block(
  fill: rgb("#2e9bff"),
  radius: 30pt,
  inset: (x: 30pt, y: 20pt),
  width: 100%,
)[
  #align(left)[
    #text(
      fill: white,
      size: 30pt,
      weight: "bold",
    )[#title]
  ]
]

#let objective-card(title, body) = box(
  width: 100%,
  inset: marg,
  radius: round_height / 2 + marg,
  fill: panelalt,
)[
  #text(
    size: 25pt,
    weight: "bold",
    fill: navy,
    title,
  )

  #v(-10pt)

  #text(
    size: 22pt,
    fill: darknavy,
    body,
  )
]

#let capability-card(title, body) = box(
  width: 100%,
  inset: marg,
  radius: round_height / 2 + marg,
  fill: panelalt,
)[
  #text(
    size: 25pt,
    weight: "bold",
    fill: navy,
  )[
    #box(
      width: 5mm,
      height: 5mm,
      radius: 50%,
      fill: skyblue,
    )
    #h(2mm)
    #title
  ]

  #v(-10pt)

  #text(
    size: 22pt,
    fill: darknavy,
  )[
    #body
  ]
]


// ============================================================
// HEADER
// ============================================================
#grid(
  columns: (1fr, 2.2fr, 1fr),
  column-gutter: 15mm,
  align: horizon,

  block[
    #text(
      size: 20pt,
      weight: "bold",
    )[
      #text(fill: blue)[STUDENT:]\
      #text()[Gomes Costa Paulo Junior]
      #v(0.5mm)
      #text(fill: blue)[PROFESSOR:] \
      #text()[Rico Steiner]
      #v(0.5mm)
      #text(fill: blue)[DEGREE:] \
      #text()[Infotronics]
    ]
  ],

  align(
    center,
    block[
      #text(
        size: 25pt,
        weight: "black",
        fill: skyblue,
        tracking: 1.5pt,
      )[
        DISTRIBUTED OT TEST SUITE
      ]

      #text(
        size: 38pt,
        weight: "black",
        fill: navy,
      )[
        Development of a test probe for performing
        functional tests in OT environments.
      ]
    ],
  ),

  align(center)[
    #image(
      "../resources/img/logos/hei-en.svg",
      width: 100mm,
    )
  ]
)

#v(8mm)

// ============================================================
// The context
// ============================================================
#block[
  #title-box("Context")

  #text(size: 22pt)[
    OT environments play a critical role in the industry, as they control and monitor critical processes. Ensuring their proper operation requires functional and security testing. However, implementing these tests often involves manual intervention on multiple network devices, making the process time-consuming, difficult to reproduce, and increases the risk of human error.

    The Distributed OT Test Suite addresses this challenge by automating test campaigns through a central coordinator and probes deployed within the OT environment. These probes execute the test commands asked by the coordinator, perform various test operations, and return the results obtained.
  ]
]

#v(7mm)

#grid(
  columns: (4fr, 2fr),
  column-gutter: 15mm,

  // ============================================================
  // TEST BENCH
  // ============================================================
  block[
    #title-box("Test bench")

    #text(
      size: 22pt,
    )[
      The test bench was used to validate the probe in a realistic distributed OT environment. It consists of multiple probes, a coordinator, and network devices, allowing the probe's communication, configuration, and testing capabilities to be evaluated.

      The architecture of the test bench is illustrated in the diagram below.
    ]

    #box(
      width: 100%,
      height: 110mm,
      radius: 3mm,
    )[
      #align(
        center,
        figure(
          fit(
            banctest-size.w - 1cm,
            banctest-size.h,
            banctest(),
          ),
          caption: none,
        ),
      )
    ]
  ],

  // ============================================================
  // CAPABILITIES
  // ============================================================
  block[
    #title-box("Capabilities")

    #v(6mm)

    #grid(
      columns: 1fr,
      row-gutter: 5mm,

      capability-card(
        "Ping",
        "Verify network connectivity and measure the response time.",
      ),

      capability-card(
        "Capture",
        "Captures the traffic passing through a network interface.",
      ),

      capability-card(
        "Portscan",
        "Scan a target to identify open ports and available services.",
      ),

      capability-card(
        "HTTP",
        "Support generic HTTP request command.",
      ),

      capability-card(
        "TCP",
        "Support sending generic TCP data.",
      ),

      capability-card(
        "UDP",
        "Support sending generic UDP data.",
      ),

      capability-card(
        "PCAP sending",
        "Replay predefined network traffic from a PCAP file.",
      ),
    )
  ],
)

#v(7mm)

#grid(
  columns: (
    1fr,
    1fr,
  ),
  column-gutter: 16mm,
  row-gutter: 10mm,

  // ============================================================
  // OBJECTIVES
  // ============================================================
  block[
    #title-box("Objectives")

    #text(
      size: 22pt,
    )[
      The objective of this Bachelor’s thesis is to develop a probe that can be deployed within an OT environment to perform distributed test operations.

      The probe must fulfill five main objectives.
    ]

    #grid(
      columns: 1fr,
      rows: (
        auto,
        auto,
        auto,
        auto,
        auto,
      ),
      row-gutter: 5mm,

      objective-card(
        "Register with a coordinator",
        "The probe must register with a coordinator, allowing deployed probes to be identified and managed remotely.",
      ),

      objective-card(
        "Announce capabilities and configurable parameters",
        "The probe must announce its supported capabilities and configurable parameters, allowing the coordinator to determine which test operations it can perform and which settings can be modified remotely.",
      ),

      objective-card(
        "Receive and execute commands",
        "The probe must receive and execute commands sent by the coordinator and return the corresponding results.",
      ),

      objective-card(
        "Support and save configuration",
        "The probe must apply configuration changes received remotely from the coordinator and store them locally so they are preserved across restarts.",
      ),

      objective-card(
        "Maintain local logs",
        "The probe must maintain local logs of executed commands and configuration changes for monitoring, troubleshooting, and operation tracking.",
      ),
    )
  ],

  // ============================================================
  // ARCHITECTURE
  // ============================================================
  block[
    #title-box("Architecture")

    #text(size: 22pt)[
      The probe software is organized into several packages, each responsible for a specific part of its functionality. This modular architecture separates the different responsibilities of the application while allowing the components to interact with each other.

      The following diagram below presents the packages and their interactions.
    ]

    #box(
      width: 100%,
      height: 210mm,
      radius: 3mm,
    )[
      #align(
        center,
        figure(
          fit(
            system-overview-size.w - 3cm,
            system-overview-size.h,
            system-overview(),
          ),
          caption: none,
        )
      ),
    ]
  ],
)
