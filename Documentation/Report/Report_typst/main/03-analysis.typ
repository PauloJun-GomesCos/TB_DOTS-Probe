#import "../metadata.typ": *
#pagebreak()
= #i18n("analysis-title", lang:option.lang) <sec:analysis>

#option-style(type:option.type)[
  In the analysis part a so called ”State of the Art” research is done. It describes the knowledge about the studied matter through the analysis of similar or related published work. It provides a comprehensive overview of what was done, what has been done in the field and what should be further investigated.

  A State of the Art is done in multiple phases:

  + Problem formulation (Research questions)
  + Literature search
  + Literature evaluation
  + Analysis and interpretation
  + Presentation

  Good sources for a literature search depend on your subject matter. For engineering hereafter a incomplete list:
  - #link("https://ieeexplore.ieee.org/")[IEEE Xplore]
  - #link("https://www.sciencedirect.com")[Science Direct]
  - #link("https://scholar.google.com")[Google Scholar]
  - #link("https://link.springer.com")[Springer Link]
  - #link("https://www.proquest.com")[ProQuest]
  - #link("https://www.jstor.org")[JSTOR]
  - #link("https://books.google.com")[Google Books]
]

This section presents the analysis conducted to identify a suitable hardware platform for the development of the probe. 

The analysis first defines the hardware requirements derived from the overall architecture of the probe. Several hardware platforms were then investigated and compared based on these requirements. The NanoPi R5S, the Odroid H4 combined with a Netcard 3, and the Raspberry Pi devices available at the school were considered as potential solutions. The section concludes with the selection of the hardware platform used for the implementation of the probe.

#add-chapter(
  after: <sec:analysis>,
  before: <sec:design>,
  minitoc-title: i18n("toc-title", lang: option.lang)
)[
  #pagebreak()
  == Hardware requirements
  As part of this project, several hardware constraints were defined to ensure the proper operation of the probe. The main requirements included the presence of at least *three Ethernet ports*, as well as compatibility with a *Linux* operating system to enable the execution of applications developed in Go.

  More specifically, the probe requires three network interfaces to fulfil its different roles. Two Ethernet interfaces are dedicated to the test network. Having two separate interfaces is necessary to allow the probe to operate as a network bridge: the probe can be placed between two network devices, with each device connected to one of the two interfaces. The two interfaces can then be bridged so that traffic can be forwarded transparently from one side to the other while being monitored by the probe. The third interface is dedicated to the coordination network and is used for communication with the coordinator through the MQTT broker. This dedicated interface keeps the coordination traffic separate from the traffic exchanged through the test interfaces.

  Based on these requirements, three hardware solutions were considered: the NanoPi R5S, the Odroid H4 combined with a Netcard 3, and the Raspberry Pi devices available at the school. These Raspberry Pi is limited to two Ethernet ports, but an additional network interface can be achieved by using Wi-Fi to connect to the manager.

  == NanoPi R5S
  The first potential hardware platform considered for the probe was the NanoPi R5S.

  #figure(
    image(
      "/resources/img/NanoPi_R5S.JPG",
      width: 60%,
      height: 25%,
      fit: "contain",
    ),
    caption: [Nano Pi R5S #footnote[NanoPi R5S image@nanopi-r5s]],
  ) <fig:navigation-test-setup>

  The NanoPi R5S@nanopi-r5s is a compact open-source IoT gateway developed by FriendlyElec, designed for networking applications. It is powered by a Rockchip RK3568B2 processor and includes 2GB or 4GB of RAM, along with eMMC storage, providing sufficient resources for embedded network tasks. 
  
  In the context of this project, the NanoPi R5S meets the key hardware requirements. It features three Ethernet ports (two 2.5GbE and one 1GbE), which directly supports the intended architecture: two interfaces can be used for network interconnection and traffic capture, while the third is dedicated to communication with the manager. This eliminates the need for additional network hardware and simplifies deployment. 
  
  The board supports several Linux-based operating systems, ensuring compatibility with applications developed in Go. It can operate in headless mode, which is particularly suitable for a probe deployed in a network environment without direct user interaction.

  == Odroid H4 + Netcard 3
  Another option considered was to use an Odroid H4 combined with a Netcard 3.

  #grid(
    columns: (1fr, 1fr),
    gutter: 10pt,

    figure(
      image("/resources/img/Odroid_H4.jpg", width: 100%),
      caption: [Odroid H4 #footnote[Odroid H4 image@odroid-h4]],
    ),

    [
      #v(16pt)
      #figure(
        image("/resources/img/Netcard_3.jpg", width: 100%),
        caption: [Netcard 3 #footnote[Odroid H4 image@odroid-netcard3]],
      )
    ],
  ) <fig:Odroid-Netcard>

  The ODROID-H4@odroid-h4 is a compact x86 single-board computer developed by Hardkernel, designed for network, edge computing, and lightweight server applications. It is powered by an Intel processor N97 and supports DDR5 RAM, offering significantly higher general purpose computing performance compared to ARM-based alternatives. In this project, it is paired with the Netcard 3 expansion board@odroid-netcard3, which provides additional high-speed network interfaces.

  In the context of this project, the ODROID-H4 combined with the Netcard 3 meets the required hardware constraints. The system offers multiple Ethernet interfaces which makes it well-suited for a multi-interface architecture where traffic capture, network interconnection, and management communication must be logically separated.
  The ODROID-H4 runs standard x86 Linux distributions, ensuring full compatibility with Gobased applications and common networking tools. Like the NanoPi R5S, it can operate in headless mode, making it suitable for deployment as a network probe without direct user interaction.
  
  #colbreak()

  == Raspberry Pi 4
  The third option investigated was to use the Raspberry Pi devices available at the school.

  #figure(
    image(
      "/resources/img/Raspberry_Pi_4.png",
      width: 50%,
      height: 25%,
      fit: "contain",
    ),
    caption: [The CNet box (Raspberry Pi 4) #footnote[The image of the CNet box comes from a CNet laboratory]],
  ) <fig:raspberry-pi-4>

  The third option considered is the use of a Raspberry Pi 4. These devices are available at the school and have already been used in other courses, making them a convenient and accessible platform for development and testing. However, the Raspberry Pi 4 does not fully meet the project requirements, as it only provides two Ethernet interface. To compensate for this limitation, Wi-Fi can be used as an additional network connection to communicate with the manager while Ethernet is used for the other network roles. 

  == Hardware selection
  The NanoPi R5S was selected as the hardware platform for the probe. It provides the required three Ethernet interfaces directly, allowing the proposed network architecture to be implemented without any additional network hardware. Two interfaces can be dedicated to the test network, while the third can be used for the coordination network.

  The NanoPi R5S also provides sufficient computing resources for the probe's workload, including network testing, packet capture, and the execution of the Go application. Its Linux compatibility allows all the required networking tools and libraries to be used, while its compact form factor and headless operation are well suited to deployment as a dedicated network probe.

  Although the ODROID-H4 with the NetCard 3 provides greater computing performance and additional network interfaces, these capabilities are not required for this project and come with additional cost and hardware complexity. The Raspberry Pi 4 is readily available and suitable for development, but its two Ethernet interfaces do not directly satisfy the required architecture and would require Wi-Fi to provide the coordination interface.

  The NanoPi R5S therefore provides the best balance between network interfaces, performance, simplicity, cost, and suitability for the intended deployment.
]
