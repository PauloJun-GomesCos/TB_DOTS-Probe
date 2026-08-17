package app

import (
	"Code/mqttclient"
	"Code/probe/config"
	"Code/probe/probe"
	"Code/probe/services"
	"Code/probe/status"
	"context"
	"log"
	"os"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

// State represents the current state of the probe application.
type State int

const (
	StateStarting State = iota
	StateConnecting
	StateRunning
)

func RunProbe() {

	// Start the application in the initialization state.
	state := StateStarting

	var (
		Probe            *probe.Probe
		mqttClient       *mqttclient.MQTTClient
		goroutineStarted bool
		ctx              context.Context
		cancel           context.CancelFunc
	)

	for {

		switch state {

		case StateStarting:
			log.Println("[APP] State: STARTING")

			// Create and initialize the probe.
			Probe = probe.NewProbe()

			// Define the MQTT topic-to-callback mapping.
			handlersMap := map[string]mqtt.MessageHandler{
				"probes/" + Probe.ID + "/command": func(client mqtt.Client, msg mqtt.Message) {
					Probe.HandleCommand(string(msg.Payload()))
				},
				"probes/" + Probe.ID + "/control": func(client mqtt.Client, msg mqtt.Message) {
					Probe.HandleControl(string(msg.Payload()))
				},
				"probes/discover": func(client mqtt.Client, msg mqtt.Message) {
					Probe.HandleDiscover(string(msg.Payload()))
				},
			}

			// Create the configuration parameters for the configuration broker
			// using the values provided through environment variables.
			brokerConfigParams := mqttclient.Params{
				Broker:   os.Getenv("MQTT_BROKER"),
				ClientId: Probe.ID,
				Username: os.Getenv("MQTT_USERNAME"),
				Password: os.Getenv("MQTT_PASSWORD"),
				Timeout:  2 * time.Second,
			}
			Probe.BrokerConfigParams = brokerConfigParams

			// Update the test broker parameters using the probe configuration.
			Probe.UpdateBrokerTestParams()

			// Search for an available MQTT broker on the network.
			Probe.FindBroker()

			// Create the MQTT client using the broker that was detected.
			if Probe.ConnectedBroker == "ConfigBroker" {
				mqttClient = mqttclient.NewMQTTClient(Probe.BrokerConfigParams)
			} else if Probe.ConnectedBroker == "TestBroker" {
				mqttClient = mqttclient.NewMQTTClient(Probe.BrokerTestParams)
			} else {
				log.Fatal("Broker unknown")
			}

			// Subscribe to the required MQTT topics and associate each topic with its corresponding callback.
			err := mqttClient.Subscribe(handlersMap)
			if err != nil {
				log.Println("[APP] Error initial subscribing:", err)
			}

			// Associate the MQTT client with the probe.
			Probe.MqttClient = mqttClient

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

			// Initialization is complete, so move to the running state.
			state = StateRunning

		case StateConnecting:
			log.Println("[APP] State: CONNECTING")

			// Search for an available MQTT broker on the network.
			Probe.FindBroker()

			connected := false

			// Continue trying to connect until the connection is established
			for !connected {
				time.Sleep(1000 * time.Millisecond)

				// Reconfigure the MQTT client according to the detected broker.
				if Probe.ConnectedBroker == "TestBroker" {
					log.Println("[APP] Trying to connect to the test broker")
					mqttClient.Reconfigure(Probe.BrokerTestParams)
				} else if Probe.ConnectedBroker == "ConfigBroker" {
					log.Println("[APP] Trying to connect to the config broker")
					mqttClient.Reconfigure(Probe.BrokerConfigParams)
				}

				// Wait for an MQTT connection event.
				select {
				case evt := <-mqttClient.Events:
					if evt == mqttclient.EventMQTTConnected {
						log.Println("[APP] Receive event EventMQTTConnected")

						// The connection was successfully established.
						connected = true
						state = StateRunning
					}
					if evt == mqttclient.EventMQTTConnectionFailed {
						log.Println("[APP] Receive event EventMQTTConnectionFailed")
					}
				}
			}

		case StateRunning:
			log.Println("[APP] State: RUNNING")

			// Announce the probe to the MQTT coordinator.
			Probe.SendMsgAnnounce(nil)

			// Start the periodic status goroutine only once.r
			if !goroutineStarted {
				probe.UpdateChannel = make(chan config.ProbeConfigParams, 1)

				// Create a context used to stop the status goroutine when the MQTT connection is lost.
				ctx, cancel = context.WithCancel(context.Background())
				log.Println("[APP] Creating context:", ctx)
				go status.SendStatus(ctx, probe.UpdateChannel, Probe)
				goroutineStarted = true
			}

			// Monitor MQTT events while the probe is running.
			running := true
			for running {
				select {
				case evt := <-mqttClient.Events:
					// A lost MQTT connection requires the probe to return to the connecting state.
					if evt == mqttclient.EventMQTTDisconnected {
						log.Println("[APP] Receive event EventMQTTDisconnected")
						state = StateConnecting

						// Stop the periodic status goroutine.
						cancel()
						goroutineStarted = false
						running = false
					}
				}
			}
		}
	}
}
