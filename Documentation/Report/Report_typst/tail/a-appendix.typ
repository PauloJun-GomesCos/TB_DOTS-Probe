#import "/metadata.typ": *
#pagebreak()
= #i18n("appendix-title", lang: option.lang) <sec:appendix>

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

== Deployement 

=== #endpoint("Dockerfile") used to build the image
/*The #endpoint("Dockerfile") defines how the probe application is built and packaged into a Docker image.*/ Here is the #endpoint("Dockerfile") used to create the probe image

```text
FROM golang:1.26 AS deps

WORKDIR /app

RUN apt-get update && apt-get install -y libpcap-dev && rm -rf /var/lib/apt/lists/*

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

FROM deps AS build
COPY . .

RUN --mount=type=cache,target=/go/pkg/mod go build -o /out/probeBin .

FROM debian:bookworm-slim AS probe

RUN apt-get update && apt-get install -y libpcap0.8 ca-certificates nmap dnsmasq procps util-linux && rm -rf /var/lib/apt/lists/*

WORKDIR /
COPY --from=build /out/probeBin /probe/probe

RUN mkdir -p /probe/config

ENTRYPOINT ["/probe/probe"]
```

#colbreak()

=== #endpoint("docker-compose.yml")
/*The #endpoint("docker-compose.yml") file defines how the probe container is deployed and configured. It specifies the container settings, required privileges, network configuration, environment variables, and mounted resources.*/ Here is the #endpoint("docker-compose.yml") used to deploy the probe image:

```text
services:
  probe:
    image: ghcr.io/paulojun-gomescos/code-probe:latest
    build:
      context: .
      dockerfile: Dockerfile
    platform: "linux/arm64"
    working_dir: /
    environment:
      - PROBE_CONFIG_PATH=${PROBE_CONFIG_PATH}
      - MQTT_BROKER=${MQTT_BROKER}
      - MQTT_USERNAME=${MQTT_USERNAME}
      - MQTT_PASSWORD=${MQTT_PASSWORD}
    volumes:
      - probe_data:/probe/config
    restart: unless-stopped
    network_mode: host

volumes:
  probe_data:
```

=== #endpoint(".env") file (environment variables)
/*The #endpoint(".env") file contains the environment-specific parameters required to deploy the probe. It specifies the path to the file used to store the probe configuration, as well as the MQTT credentials required to connect to the broker of the configuration environment. The #endpoint(".env") file is documented by the #endpoint(".env.example") file: */

Here is the #endpoint(".env.example") file, which documents the #endpoint(".env") file required for the probe deployement :

```text
# Path to the file containing the probe configuration
PROBE_CONFIG_PATH=probe/config/probeConfig.json

# MQTT credentials for the configuration broker
MQTT_BROKER=UrlBrokerConfig
MQTT_USERNAME=UsernameBrokerConfig
MQTT_PASSWORD=PasswordBrokerConfig
```

#colbreak()

=== Deployement guide
Before deploying the probe, Docker and Docker Compose must be installed on the NanoPi R5S. The device must also have network connectivity to the container registry in order to pull the probe image. Once these prerequisites are installed and the device is connected to the required networks, the probe can be deployed using the following steps.

The following steps describe how the probe is deployed on the NanoPi R5S.
1. Connect to the NanoPi R5S using SSH:

  ssh root\@\<NanoPi_IP_Address>

  password: fa

1. Create a "probe" directory on the NanoPi R5S
2. Add the #endpoint("docker-compose.yml") file to the directory
3. Copy the #endpoint(".env.example") in the #endpoint(".env") file and fill in the MQTT credentials of the broker of the configuration environment
4. Pull the docker image from #endpoint("ghcr.io")
```shell
docker compose pull
```
5. Start the probe container
```shell
docker compose up -d
```

/*
== Add new capability to the probe
Cette annexe contient un guide qui explique comment ajouter une nouvelle capabilité au probe et quelle soit envoyé dans le message d'announce avec le format contenant les metadatas pour son affichage sur lînterface web du coordinateur.

*1.* Implémenter la fonction executor qui permet d'éxecuter la nouvelle commande. 
- Crée un nouveau fichier .go dans le package #endpoint("probe.services")
- Implémente la fonction qui permet d'éxecuter la nouvelle commande dans le .go crée en suivant cette example:
```go
  func PingExecute(msgCommand models.MsgCommandRequest, p *probe.Probe)
```

*2.* Ajouter une nouvelle liaison à la map d'executors implémenté dans le package #endpoint("probe.app"). Il faut ajouter une liaison qui lie le nom de la commande avec la fonction crée précedement. Voici un exemple des liaisons acctuels du probe : 
```go
  // Register the executors available for processing commands.
  Probe.Executors["ping"] = services.PingExecute
  Probe.Executors["capture"] = services.CaptureExecute
  Probe.Executors["portscan"] = services.PortscanExecute
  Probe.Executors["http"] = services.HTTPExecute
  Probe.Executors["udp"] = services.UDPExecute
  Probe.Executors["udp-server"] = services.UDPServerEchoExecute
  Probe.Executors["tcp"] = services.TCPExecute
  Probe.Executors["tcp-server"] = services.TCPServerEchoExecute
  Probe.Executors["pcap-file"] = services.PcapExecute
```

*3.* Il faut ensuite ajouter l'annonce de cette capabilité dans le message d'announcement. Pour ce faire il faut créer une variable dans le package #endpoint("probe.capabilities") qui implémente la struct #endpoint("models.Capability") décrite dans la section 5.5 du rapport avec les bonnes informations liée a la nouvelle commande implémenté. 

Voici un exemple d'implémentation de cette structure: 
```go
// PingCapability fully defines the ping command
var PingCapability = models.Capability{
	Action:      "ping",
	Label:       "Ping",
	Icon:        "network_ping",
	Description: "ICMP echo request test.",

	Params: []models.CapabilityParam{
		{Key: "interface", Label: "Interface", Type: "string", Example: "eth1"},
		{Key: "target", Label: "Target", Type: "string", Example: "google.ch"},
		{Key: "count", Label: "Packet count", Type: "number", Example: 4, Min: 1, Max: 100},
		{Key: "timeout_ms", Label: "Timeout", Type: "number", Example: 1000, Min: 100, Max: 30000},
	},
	Expected: []models.Result{
		{Key: "packets_sent"},
		{Key: "packets_received"},
		{Key: "packet_loss_percent"},
		{Key: "rtt_min_ms"},
		{Key: "rtt_avg_ms"},
		{Key: "rtt_max_ms"},
	},
}
```

Il faut ensuite l'ajouter dans la variable #endpoint("CapabilitiesList") dans le package #endpoint("probe.capability")
*/