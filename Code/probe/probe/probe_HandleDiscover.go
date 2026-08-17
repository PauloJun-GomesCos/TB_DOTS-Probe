package probe

import (
	"Code/models"
	"encoding/json"
	"log"
)

// HandleDiscover processes discovery messages received through the probes/discover topic.
func (p *Probe) HandleDiscover(payload string) {
	log.Printf("[DISCOVER handler] Receive a discover message with the payload : [%s]", payload)

	var msgDiscover models.MsgDiscoverRequest

	err := json.Unmarshal([]byte(payload), &msgDiscover)
	if err != nil {
		log.Println("[DISCOVER handler] Failed to unmarshal the payload :", err)
	}

	// Respond to the discovery request by announcing the probe and including the request ID received from the coordinator.
	p.SendMsgAnnounce(&msgDiscover.RequestID)
}
