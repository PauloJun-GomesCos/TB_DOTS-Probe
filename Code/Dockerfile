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