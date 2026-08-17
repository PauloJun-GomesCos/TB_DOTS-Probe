package mqttclient

import (
	"Code/models"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

// MQTTEvent represents an event related to the MQTT connection state.
type MQTTEvent int

const (
	EventMQTTConnected MQTTEvent = iota
	EventMQTTDisconnected
	EventMQTTConnectionFailed
)

// Params contains the parameters required to establish an MQTT connection.
type Params struct {
	Broker   string
	ClientId string
	Username string
	Password string
	QOS      byte

	Timeout time.Duration
}

// subscribe records an MQTT topic with its corresponding callback so it can be replayed when the client reconnect.
type subscribe struct {
	topic    string
	callback mqtt.MessageHandler
}

// MQTTClient wraps the Paho MQTT client and provides additional functionality for connection management and subscription.
type MQTTClient struct {
	client mqtt.Client
	mu     sync.RWMutex

	Params   Params
	Events   chan MQTTEvent
	SubsList []subscribe
}

// NewMQTTClient creates and initializes a new MQTT client using the provided connection parameters.
func NewMQTTClient(params Params) *MQTTClient {
	log.Println("[MQTTClient]: Creating a new MQTT client")

	mqttClient := &MQTTClient{
		Params: params,
	}

	// Create the underlying Paho MQTT client and configure its options.
	mqttClient.client = mqtt.NewClient(mqttClient.setClientOptions(params, true))

	// Create a buffered channel used to notify the probe of MQTT events.
	mqttClient.Events = make(chan MQTTEvent, 10)

	// Attempt to establish the initial connection to the broker.
	mqttClient.Connect()

	return mqttClient
}

// setClientOptions creates and configures the Paho MQTT client options.
func (m *MQTTClient) setClientOptions(params Params, connectRetry bool) *mqtt.ClientOptions {
	opts := mqtt.NewClientOptions()
	// Configure the MQTT broker and client identification.
	opts.AddBroker(params.Broker)
	opts.SetClientID(params.ClientId)

	// Configure the MQTT keep-alive and connection retry behaviour.
	opts.SetKeepAlive(10 * time.Second)
	opts.SetAutoReconnect(false)
	opts.SetMaxReconnectInterval(2 * time.Second)
	opts.SetConnectRetry(connectRetry)
	opts.SetConnectRetryInterval(1 * time.Second)

	// Configure authentication if credentials are provided.
	if params.Username != "" {
		opts.SetUsername(params.Username)
		opts.SetPassword(params.Password)
	}

	// Configure TLS when a client ID is provided.
	if params.ClientId != "" {
		pool := x509.NewCertPool()
		tlsCfg := &tls.Config{
			RootCAs:            pool,
			InsecureSkipVerify: true,
		}
		opts.SetTLSConfig(tlsCfg)
	}

	// Configure the MQTT Last Will message. It is published by the broker if the client disconnects unexpectedly.
	msgLastWill := &models.MsgLastWill{
		State: "offline",
	}
	msgLastWillPayload, err := json.Marshal(msgLastWill)
	if err != nil {
		log.Fatal(err)
	}
	opts.SetWill("probes/"+params.ClientId+"/status", string(msgLastWillPayload), 1, false)

	// Callback executed when the client successfully connects to the broker.
	opts.OnConnect = func(c mqtt.Client) {
		log.Println("[MQTT GATEWAY] Connected successfully to the broker at", params.Broker)
		if m.Events != nil {
			m.Events <- EventMQTTConnected
		}
		// Restore all previously registered subscriptions.
		m.Resubscribe(c)
	}

	// Callback executed when the connection to the broker is lost.
	opts.OnConnectionLost = func(c mqtt.Client, err error) {
		log.Println("[MQTT GATEWAY] Connection to the broker lost:", params.Broker, err)
		if m.Events != nil {
			m.Events <- EventMQTTDisconnected
		}
	}
	return opts
}

// Connect attempts to connect the MQTT client to the configured broker. Connection errors and timeouts are
// reported through the Events channel.
func (m *MQTTClient) Connect() {
	token := m.client.Connect()
	// Wait for the connection attempt to complete, up to the configured timeout.
	if !token.WaitTimeout(m.Params.Timeout) {
		if m.Events != nil {
			m.Events <- EventMQTTConnectionFailed
		}
		log.Println("[MQTT GATEWAY] Couldn't connect to broker", m.Params.Broker, " within:", m.Params.Timeout)
	}
	// Check whether the connection attempt returned an error.
	if token.Error() != nil {
		if m.Events != nil {
			m.Events <- EventMQTTConnectionFailed
		}
		log.Println("[MQTT GATEWAY] Connection to broker", m.Params.Broker, "failed:", token.Error())
	}
	log.Println("[MQTT Gateway] Connected successfully to broker", m.Params.Broker)
}

// Reconfigure replaces the current MQTT connection with a new one using the provided parameters
// The new connection is tested before replacing the current client. If the new broker cannot be reached,
// the previous connection is restored.
func (m *MQTTClient) Reconfigure(params Params) {
	log.Println("[MQTT Gateway] Reconfigure the mqtt client]")
	// Keep a reference to the current client so it can be restored if the new connection attempt fails.
	old := m.client
	old.Disconnect(250)

	// Create a new MQTT client using the new configuration.
	newClient := mqtt.NewClient(m.setClientOptions(params, true))

	// Test the new broker before replacing the current client.
	token := newClient.Connect()
	if token.WaitTimeout(m.Params.Timeout) {
		if token.Error() != nil {
			newClient.Disconnect(0)
			log.Println("[MQTT GATEWAY] Broker", params.Broker, "is not reachable:", token.Error())
			if m.Events != nil {
				m.Events <- EventMQTTConnectionFailed
			}
			// Restore the previous MQTT connection.
			old.Connect()
			return
		}
	} else {
		newClient.Disconnect(0)
		log.Println("[MQTT Gateway] Broker", params.Broker, "not reachable within", m.Params.Timeout)
		if m.Events != nil {
			m.Events <- EventMQTTConnectionFailed
		}
		// Restore the previous MQTT connection.
		old.Connect()
		return
	}

	// Replace the client and its configuration atomically.
	m.mu.Lock()
	m.client = newClient
	m.Params = params
	m.mu.Unlock()

	log.Printf("[MQTT GATEWAY] reconfigured, now connected to %s", params.Broker)
	return
}

// Resubscribe resubscribes the MQTT client to its previously configured topics after reconnecting to a broker.
func (m *MQTTClient) Resubscribe(client mqtt.Client) {
	log.Println("[MQTT Gateway] Resubscribing to all the topics")
	for _, s := range m.SubsList {
		token := client.Subscribe(s.topic, 0, s.callback)
		if token.WaitTimeout(m.Params.Timeout) {
			if token.Error() != nil {
				log.Println("[MQTT Gateway] Resubscribe to", s.topic, "failed:", token.Error())
			}
		} else {
			log.Println("[MQTT Gateway] Resubscribe to", s.topic, "timed out")
		}
		log.Println("[MQTT GATEWAY] Resubscribed successfully to topic", s.topic)
	}
}

// Subscribe subscribes to the specified MQTT topics and associates each topic with its corresponding message handler.
func (m *MQTTClient) Subscribe(handlers map[string]mqtt.MessageHandler) error {
	for topic, handler := range handlers {
		// Store the subscription for future reconnections.
		m.SubsList = append(m.SubsList, subscribe{
			topic:    topic,
			callback: handler,
		})

		// Subscribe to topic.
		token := m.client.Subscribe(topic, m.Params.QOS, handler)

		// Wait for subscription confirmation and check errors.
		if token.WaitTimeout(m.Params.Timeout) {
			if token.Error() != nil {
				return fmt.Errorf("[MQTT Gateway] Subscribe to %s failed: %w", topic, token.Error())
			}
		} else {
			return fmt.Errorf("[MQTT Gateway] Subscribe to %s timed out", topic)
		}
		log.Println("[MQTT GATEWAY] Subscribed successfully to", topic)
	}
	return nil
}

// Publish publishes a message with the given payload to the specified MQTT topic.
func (m *MQTTClient) Publish(topic string, payload string) error {
	// Publish the payload
	token := m.client.Publish(topic, m.Params.QOS, false, payload)

	// Wait for the publication to complete and check for errors.
	if token.WaitTimeout(m.Params.Timeout) {
		if token.Error() != nil {
			return fmt.Errorf("[MQTT Gateway] Publish to %s failed: %w", topic, token.Error())
		}
	} else {
		return fmt.Errorf("[MQTT Gateway] Publish to %s timed out", topic)
	}
	log.Println("[MQTT GATEWAY] Published successfully to", topic)
	return nil
}
