#import "../metadata.typ": *

#import "/resources/diagram/fit.typ": fit
#import "/resources/diagram/TestBench-Diagram.typ": (
  testbench, testbench-size
)

#pagebreak()
= #i18n("validation-title", lang:option.lang) <sec:validation>

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
  In addition to presenting the *results of your research in relation to your research question*, it is imperative that the validation section of your bachelor's thesis adheres to certain principles to ensure clarity, coherence, and rigor. Here are some additional considerations to enhance the validation process:

  - *Objective Description of Data*: Provide an objective and detailed description of the data used in your analysis.
  - *Utilize Graphs and Tables*: Visual aids such as graphs, charts, and tables can greatly enhance the clarity and impact of your results presentation.
  - *Link Results to Research Questions*: For each result presented, explicitly link it back to the corresponding research question or hypothesis.
  - *Ranking Results by Importance*: Prioritize your results by ranking them in order of importance or relevance to your research objectives.
  - *Confirmation or Rejection of Hypotheses*: Evaluate each result in light of the hypotheses formulated in your thesis.
]

This section presents the validation of the developed system to verify that the implemented functionalities meet the requirements defined previously. The different tests are performed using a dedicated test bench.

The validation is then divided into two main parts. First, functional tests are performed to verify that the implemented functionalities behave as expected and that the system requirements are fulfilled. Second, limit tests are conducted to identify the limitations of the probe and evaluate its behaviour as the workload increases. Finally, a conclusion summarizes the different tests performed and the main results obtained.


#add-chapter(
  after: <sec:validation>,
  before: <sec:conclusion>,
  minitoc-title: i18n("toc-title", lang: option.lang)
)[
  #pagebreak()
  == Testbench 
  To demonstrate and test the different capabilities of the probe under conditions close to its real-world use, a test bench was set up. It reproduces a test environment consisting of several network devices and makes it possible to perform various tests on a real device.
 
  The test bench consists of three probes, *SEP0*, *Bridge*, and *LAN*, as well as a coordinator implementing the MQTT broker. It also includes two HOOC Connect XT devices. The first one serves as the DUT (Device Under Test), its the device on which the various tests are performed. The second HOOC Connect XT provides Internet access to the coordination network.
 
  The test bench consists of two separate networks: the coordination network and the test network.

  The coordination network uses the #endpoint("10.0.0.0/24") subnet. It is used for communication between the coordinator and the different probes deployed in the test environment.

  The test network corresponds to the networks on which the various tests are performed. The DUT separates this network into two parts. The SEP0 side uses the #endpoint("192.168.2.0/24") subnet, while the LAN side uses the #endpoint("192.168.3.0/24") subnet. Two probes are deployed on the SEP0 side: the SEP0 probe and the Bridge probe. On the LAN side of the DUT, only the LAN probe is deployed. 

  The diagram below presents the complete architecture of the test bench and the connections between the different devices.
  
  #figure(
    fit(testbench-size.w - 2cm, testbench-size.h, testbench()),
    caption: [Test bench],
  ) <test-bench>

  #colbreak()

  The testbench was configured to reproduce the different network configuration scenarios that a probe may encounter in a test environment. Static IP addresses were assigned to the coordination network interfaces to simulate a test environment without a DHCP server. The Bridge Probe was configured to operate as a bridge between its test interfaces, with a static IP address assigned to the bridge interface. Similarly, a static IP address was assigned to the eth2 interface of SEP0. In contrast, the eth2 interface of the LAN Probe receives its IP address dynamically from a DHCP server provided by the HOOC. This configuration allows both static and dynamic IP address assignment to be tested within the same testbench.

  == Functionnal tests
  Various functional tests were performed in the test bench to validate the operation of the probe and verify that all the requirements defined previously were correctly implemented and functional.

  *Parameter configuration and save*

  First, tests were performed to verify that configuration changes sent by the coordinator were correctly applied by the probe. Different parameters were modified through the coordinator, and their values were then checked on the probe to confirm that the changes had been correctly received and applied. The probe was then restarted to verify that the new configurations were properly saved and restored after a restart.

  *Interface configuration*

  Tests were also performed to validate the different network interface configurations supported by the probe. The static IP configuration was tested by manually assigning an IP address to an interface through the coordinator and verifying that the configuration was correctly applied. Dynamic configuration was also tested to verify that the probe's interfaces could automatically obtain an IP address through DHCP. The probe's ability to operate as a DHCP server on a test interface was also verified by connecting devices to the interface and checking that they could successfully obtain an IP address. Finally, the bridge mode was validated by configuring eth1 and eth2 as a bridge and verifying that network traffic could pass through the probe transparently. These tests confirmed that the network configurations required for the probe to operate in in both system environments were correctly supported.

  *Multi-environement*

  Tests were also performed to validate the MQTT connection management in both environments. The probe was successively connected to the configuration broker and the test broker to verify that it could correctly detect and establish a connection with each of them. Disconnections were then intentionally triggered to verify that the probe detected the loss of connection and automatically attempted to re-establish communication with the available broker.

  The probe was also moved from one environment to the other to verify that it could detect the network change and connect to the corresponding broker. These tests validated the probe's connection, reconnection, and broker switching mechanisms, which are essential for the probe to operate correctly across the two environments defined by the system.

  *Command testing*

  Functional tests were also performed for the different commands available on the probe. Several test suites were created directly from the coordinator's web interface to group and execute different test scenarios. Each command was tested with different parameters to verify that it could be correctly received and executed, and that the returned result matched the expected behavior. Invalid parameters were also used to verify the error handling mechanisms.
  
  *Dynamic definition*

  The dynamic definition of commands and configuration parameters by the probe was also tested through the coordinator's web interface. The objective was to verify that all metadata required to display and configure commands and parameters is provided by the probe itself. The information announced by the probe was correctly interpreted and displayed by the web interface. 
  
  During the development of the probe, new commands and configuration parameters were progressively implemented and added to the announced capabilities. Each of them appeared automatically in the web interface with the corresponding information, without requiring any modification to the coordinator. This validates the dynamic behavior of the interface and confirms that the probe provides all the metadata required for the coordinator to display and handle the probe capabilities and configuration parameters.

  *Summary of functional test*

  The functional tests presented in this section were used to validate the different requirements defined in section 4.2. The following table summarizes the requirements covered by the tests and the corresponding test section used for their validation.

  #figure(
    table(
      columns: (5cm, 9cm),
      stroke: 0.8pt,
      inset: 5pt,
      align: left,

      table.header(
        [*Requirement*],
        [*Validation*],
      ),

      [The probe registers with the coordinator and announces its capabilities and configuration parameters],
      [Validated through the tests presented in *Dynamic definition*, which verify that the probe correctly registers with the coordinator and provides the metadata required to dynamically display its capabilities and configuration parameters.],

      [The probe applies configuration changes and saves the configuration],
      [Validated through the tests presented in *Parameter configuration and save*, which verify that configuration changes are correctly applied and preserved after a restart.],

      [The probe supports the required network interface configurations],
      [Validated through the tests presented in *Interface configuration*, covering static and dynamic IP configuration, DHCP client configuration, DHCP server configuration, and bridge mode.],

      [The probe receives commands, executes them, and sends the corresponding results],
      [Validated through the tests presented in *Command testing*, where the available commands are executed with valid and invalid parameters and their results and error handling are verified.],

      [The probe identifies and connects to the appropriate broker],
      [Validated through the tests presented in *Multi-environment*, which verify broker detection, connection, reconnection after a disconnection, and broker switching when moving between the two environments.],
 
    ),
    caption: [Summary of functional test validations],
  ) <tbl:Functional-test-requirements>

  == Limit tests
  In addition to the functional tests, several other tests were performed to evaluate the limits of the probe and observe its behavior under higher loads. The objective was to determine whether the probe remained functional when handling a large number of commands or network operations simultaneously, and to identify any performance limitations that could affect its use in a real environment.

  === Capture size limit
  When the probe performs a network capture, the captured packets are temporarily stored in a PCAP file. Once the capture is completed, the content of this file is read, encoded in Base64 and sent to the coordinator before the temporary file is deleted.
  
  Tests were performed to determine the maximum capture size that the probe can handle. For this purpose, iperf@iperf was used to continuously generate network traffic between two probes. An iperf server was started on the SEP0 probe and an iperf client on the Bridge probe. A network capture was then started on the Bridge probe while the client continuously generated traffic. The size of the temporary PCAP file was monitored throughout the capture.

  When the PCAP file size exceeded approximately *325 MB*, the probe process was terminated by the Linux kernel because of excessive memory consumption. This issue is caused by the way the PCAP file is prepared before being sent. First, the entire file is read into memory, resulting in an additional memory consumption approximately proportional to the file size. The data is then encoded into Base64, which requires an additional large memory allocation. Finally, the Base64-encoded data is included in the JSON response and serialized using #endpoint("json.Marshal"), resulting in further memory allocations before the message is published through MQTT. Beyond approximately *325 MB* per PCAP file, the memory required to process and serialize the file for transmission can exceed the available memory of the hardware, causing the Linux kernel's OOM (Out-Of-Memory) killer to terminate the probe process.
  
  It was also observed that the maximum message size supported by MQTT is smaller than the maximum PCAP file size that the probe can handle. Therefore, when transmitting a PCAP file to the coordinator, the limitation imposed by MQTT communication is reached before the probe's available RAM becomes a limiting factor. One possible solution for transmitting larger PCAP files would be to split the captured file into several parts and transmit them sequentially to the coordinator, which could then reassemble the parts to reconstruct the original file. This approach was not implemented as part of this thesis.

  === Parallel function limit
  Tests were performed to determine the maximum number of functions that the probe can execute simultaneously. Different commands were used to evaluate the probe's behavior under increasing levels of parallelism.
  
  First, load tests were performed to determine the maximum number of port scans that could be executed simultaneously by the probe. Port scans are performed using Nmap and can generate a significant load on system resources. For these tests, each port scan consisted of scanning all ports (1 to 65535) of the coordinator. The number of simultaneous port scans was progressively increased. The test started with a single port scan, and one additional port scan was added at each iteration to observe the evolution of the execution time and the behavior of the probe.
  
  As the number of commands executed in parallel increased, the average execution time of the port scans also increased. This can be explained by the increasing workload placed on the processor, which must handle a larger number of port scans simultaneously. As the available processing resources are shared among more simultaneously  portscans, the time required to complete each individual port scan increases. 
  
  Up to 23 simultaneous port scans, the execution times remained relatively consistent between the different scans. However, when more than 23 port scans were executed simultaneously, significant differences in execution time between individual scans were observed. This behavior is illustrated in the following graph.

  #figure(
    image(
      "/resources/img/Portscan_Execution_Graph.png",
      width: 90%,
      height: 30%,
      fit: "contain",
    ),
    caption: [Evolution of the execution time],
  ) <fig:navigation-test-setup>

  As shown in the graph, when 24 port scans are executed simultaneously, the maximum execution time of a port scan becomes significantly higher than the average execution time. Additional tests were performed by further increasing the number of concurrent port scans. These tests showed a recurring behavior: a group of approximately 23–24 port scans is executed simultaneously with similar execution times, while the execution times of the remaining scans become much less predictable and can be significantly longer. This behavior indicates that the probe reaches a limit in its ability to handle a high number of concurrent port scans consistently. Executing more than 23 port scans simultaneously is not recommended. Although the probe is still able to execute the commands, the execution time becomes significantly longer and less predictable, which reduces the efficiency of the probe.

  Load tests were also performed to determine the number of *ping* commands that could be executed *simultaneously* by the probe. The objective was to identify the level of parallelism at which the probe begins to experience packet loss. 
  Each ping command was targeting the IP address of the coordinator and had a ping count of 100. The ping count was fixed at 100 so the commands takes more time to execute. The number of simultaneous ping commands was then progressively increased. With *100 requests per command*, no packet loss was observed up to approximately *200 simultaneous commands*. Above this level, packet loss began to appear.

  To evaluate the influence of the number of pings performed by each command, the number of pings was then reduced from 100 to 10. With this configuration, no packet loss was observed even with *300 simultaneous commands*. However, the execution time of the commands began to increase at around 250 parallel commands. With 300 simultaneous commands, some commands required more than twice the expected execution time. This indicates a degradation in the probe's performance despite the absence of packet loss.

  These tests show that the probe is capable of executing a large number of ping commands in parallel while maintaining generally stable and reliable behavior. 
  
  Tests were also performed with TCP and UDP commands. A total of *200 commands* were executed in parallel, consisting of *100 TCP* commands and *100 UDP* commands. All commands were configured with the waiting-response parameter enabled. The tests completed successfully, with execution times ranging from approximately a few tens of milliseconds to 150 ms. This variation is considered acceptable for this type of test. As observed with the ping and port scan tests, execution times tend to increase as the number of commands executed in parallel increases. The tests were not continued beyond 200 simultaneous commands, as this level of parallelism is considered higher than what would be required in a real-world use of the probe. Performing additional tests at even higher levels of parallelism was therefore not considered particularly relevant.

  == Conclusion
  The functional and limit tests performed throughout the development allowed the main requirements defined for the probe to be validated. The tests confirmed that the probe can communicate correctly with the coordinator, manage connections to both system environments, receive and apply configuration changes, execute the implemented commands, and return the expected results. The different network configuration mechanisms, including static and dynamic IP configuration, DHCP server operation, and bridge mode, were also successfully validated.

  The limit tests also identified some constraints, particularly regarding the maximum size of PCAP captures and the performance degradation caused by a very high number of commands running in parallel.

  Overall, all the objectives defined for this thesis were successfully achieved, and the implemented probe meets the requirements established for the project.
]
