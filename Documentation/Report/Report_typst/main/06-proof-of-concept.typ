#import "../metadata.typ": *

#import "../resources/diagram/fit.typ": fit
#import "../resources/diagram/MQTT-Communication-content.typ": (
  mqtt-setup-sequence, mqtt-setup-sequence-size, mqtt-command-sequence, mqtt-command-sequence-size, mqtt-discovery-sequence, mqtt-discovery-sequence-size,
)

#pagebreak()
= Proof of concept of net.resolver <sec:proof>
This section presents the proof of concept demonstrating the use of net.Resolver, as described in the implementation section 5.6.3 addressing the issue encountered during the configuration of the network interfaces. It begins with an introduction to the problem. The method used to configure the resolver is then presented, followed by an analysis of the results obtained. Finally, the section discusses the potential usefulness of this solution for future developments of the system.

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


#add-chapter(
  after: <sec:proof>,
  before: <sec:validation>,
  minitoc-title: i18n("toc-title", lang: option.lang)
)[
  #pagebreak()
  
  == Introduction
  This section of the report explains a proof of concept demonstrating the results obtained from the implementation of #endpoint("net.resolver").
  
  As explained in the section 5.6.3 describing the issue encountered during the interface configuration, tests were conducted using #endpoint("net.resolver"). Although it was not retained in the final implementation, the results obtained were rather positive. Since this approach could potentially be useful for the future development of the project, this section describes the implementation that was tested and the results obtained.

  == Explanation of the method
  To implement the resolver, a *Resolver* object of type #endpoint("*net.Resolver") was added to the probe. A SetResolver function was then created, which takes the IP address of the DNS server as a parameter.

  The function was implemented as follows:
  ```go
  func (p *Probe) SetResolver(dnsServer string) {
    log.Println("[PROBE] Setting Resolver with DNS Server", dnsServer)
    p.Resolver = &net.Resolver{
      PreferGo: true,
      Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
        d := net.Dialer{
          Timeout: 5 * time.Second,
        }
        return d.DialContext(ctx, "udp", dnsServer+":53")
      },
    }
  }
  ```

  This function initializes the probe's resolver by creating a #endpoint("net.Resolver"). The _PreferGo_ attribute is enabled to force the use of Go's native DNS implementation. This allows the custom Dial function to be used instead of the DNS resolver provided by the operating system. The Dial function defines how connections to the DNS server are established. For each DNS request, a UDP connection is created to the specified server on port 53, which is the standard port used by the DNS protocol. A 5-second timeout is configured to prevent a blocked DNS request from indefinitely stopping the program.

  By default, the libraries used in this project, such as the one used to perform ping operations, rely on the system's default DNS resolver. Therefore, a custom function had to be implemented to resolve hostnames to IP addresses using the probe's resolver before passing them to these libraries. The following function was implemented for this purpose:
  ```go
  func (p *Probe) ResolveIPv4(ctx context.Context, target string) (string, error) {
    if ip := net.ParseIP(target); ip != nil {
      if ipv4 := ip.To4(); ipv4 != nil {
        return ipv4.String(), nil
      }
      return "", fmt.Errorf("IPv6 is not supported")
    }

    ips, err := p.Resolver.LookupIP(ctx, "ip", target)
    if err != nil {
      return "", err
    }

    for _, ip := range ips {
      if ipv4 := ip.To4(); ipv4 != nil {
        return ipv4.String(), nil
      }
    }

    return "", fmt.Errorf("no IPv4 address found for %s", target)
  }
  ```
  
  The function first checks whether the target is already a valid IPv4 address. If so, the target is returned directly, as no DNS resolution is required. If the target is not an IPv4 address, it is considered to be a hostname. The function then performs a DNS resolution using the resolver previously configured in the probe. The _LookupIP_ method sends a DNS request to retrieve the list of IP addresses associated with the hostname (target). Since a hostname can resolve to multiple IP addresses, the function iterates through the returned results and selects only IPv4 addresses. The first IPv4 address found is returned. If no IPv4 address is available among the DNS results, an error is returned.

  == Results
  The DNS server address was configured by manually setting the IP address of the DNS server used on the network to which the probe was connected. The #endpoint("/etc/resolv.conf") file was then cleared to ensure that Docker had no access to a DNS server and to properly test the implementation of #endpoint("net.resolver"). A ping to google.ch and an HTTP request to Google were then performed to verify that the program could not resolve hostnames using the system DNS configuration. As expected, both operations failed. The #endpoint("ResolveIPv4") function was then integrated into the functions responsible for executing ping and HTTP requests. The same tests were performed again. This time, both operations succeeded, demonstrating that the custom resolver was correctly resolving hostnames using the configured DNS server.

  == Futur use
  The use of #endpoint("net.resolver") could be adapted and reused in the future to configure a specific DNS server for each probe interface. If eth0, eth1, and eth2 are connected to different networks, and each network provides its own DNS server, it may be necessary to configure a custom DNS resolver for each interface. Therefore, using one #endpoint("net.resolver") per interface could be a potential approach for future development of the probes.
]
