package services

import (
	"Code/models"
	"Code/probe/probe"
	"encoding/base64"
	"log"
	"os"
	"time"

	"github.com/gopacket/gopacket"
	"github.com/gopacket/gopacket/layers"
	"github.com/gopacket/gopacket/pcap"
	"github.com/gopacket/gopacket/pcapgo"
)

// CaptureExecute executes a packet capture using the specified interface and parameters, then sends the
// captured pcap file encoded in base64 as a response.
func CaptureExecute(msgCommand models.MsgCommandRequest, p *probe.Probe) {
	log.Println("[CAPTURE] Executing capture with the parameters:", msgCommand.Params)

	// Validate the capture parameters.
	Error := ValidateCaptureParams(&msgCommand)
	if Error.Code != 0 {
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Check that the specified network interface exists actually on the probe.
	if !p.Network.CheckInterfaceExist(msgCommand.Params["interface"].(string)) {
		Error.Code = 1
		Error.Message = "[CAPTURE] Invalid parameter value: interface is unknown"
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Extract parameters from the command payload.
	device := msgCommand.Params["interface"].(string)
	filter := msgCommand.Params["filter"].(string)
	timeout := msgCommand.Params["timeout_s"].(float64)

	// Configure the packet capture
	snapshotLen := int32(1024)       // The snapshot length defines the maximum amount of data captured per packet.
	promiscuous := true              // Promiscuous mode is required to capture all traffic received by
	timeoutSend := pcap.BlockForever // Block indefinitely while waiting for packets.

	// Open the network interface for packet capture.
	handle, err := pcap.OpenLive(device, snapshotLen, promiscuous, timeoutSend)
	if err != nil {
		Error.Code = 20
		Error.Message = "[CAPTURE] Failed to open a capture session with error: " + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}
	// Ensure that the capture handle is closed when the function returns.
	defer handle.Close()

	// Apply the BPF specified in the command.
	err = handle.SetBPFFilter(filter)
	if err != nil {
		Error.Code = 1
		Error.Message = "[CAPTURE] Invalid parameter value: " + filter + " is not a valid BPF filter"
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Create a packet source that provides captured packets through a channel.
	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())

	// Create a temporary PCAP file using the command ID as its filename.
	fileName := msgCommand.ID + ".pcap"
	f, err := os.Create(fileName)
	if err != nil {
		Error.Code = 21
		Error.Message = "[CAPTURE] Error creating the temporary .pcap file:" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
	}

	writer := pcapgo.NewWriter(f)

	// Write the PCAP file header using Ethernet as the link-layer type.
	err = writer.WriteFileHeader(1600, layers.LinkTypeEthernet)
	if err != nil {
		Error.Code = 22
		Error.Message = "[CAPTURE] Error creating the file header:" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
	}

	// Create timer for the capture timeout
	timer := time.NewTimer(time.Duration(timeout) * time.Second)
	defer timer.Stop()

	// Get the channel containing captured packets.
	packets := packetSource.Packets()

	// Notify the coordinator that the capture has started and is being processed.
	p.SendProcessingResponse(msgCommand.ID)

	for {
		select {
		case <-timer.C: // The capture timeout has expired.
			// Read the temporary PCAP file into memory.
			data, _ := os.ReadFile(fileName)

			// Encode the complete PCAP file as Base64.
			b64 := base64.StdEncoding.EncodeToString(data)

			result := models.CaptureResult{
				PcapB64: b64,
			}

			p.SendSuccessResponse(msgCommand.ID, result)

			// Delete the temporary file
			err = os.Remove(fileName)
			if err != nil {
				log.Println("[CAPTURE] Error removing the temporary .pcap file : ", err)
			}
			return

		case packet, ok := <-packets: // ok indicates whether the "packets" channel is still open
			if !ok {
				// When the timer expires, returning from the function triggers handle.Close() via defer,
				// which stops the capture and closes the packets channel.
				log.Println("[CAPTURE] Closing the capture session")
				return
			}

			ci := packet.Metadata().CaptureInfo // Retrieves packet metadata (Timestamp, CaptureLength, Length, ...)
			data := packet.Data()               // Retrieves packet data

			// Write the packet (metadata + data) in the temporary file
			err = writer.WritePacket(ci, data)
			if err != nil {
				log.Println("[CAPTURE] Error writing the packet info in the temporary .pcap file : ", err)
			}
		}
	}
}

// ValidateCaptureParams Validates the capture command parameters and returns an error if any parameter is invalid.
func ValidateCaptureParams(msgCommand *models.MsgCommandRequest) models.ErrorInfo {
	Error := models.ErrorInfo{}

	requiredParams := []string{"interface", "filter", "timeout_s"}

	// Check missing params
	for _, param := range requiredParams {
		if _, exists := msgCommand.Params[param]; !exists {
			Error.Code = 4
			Error.Message = "Missing parameter: The parameter " + param + " is required to execute the capture command"
			return Error
		}
	}

	// Validate each parameter based on its expected type and constraints
	for paramName := range msgCommand.Params {
		value := msgCommand.Params[paramName]

		switch paramName {
		case "interface":
			if _, ok := value.(string); ok {
				continue
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : interface should be a string"
				break
			}
		case "filter":
			if _, ok := value.(string); ok {
				continue
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : filter should be a string"
				break
			}
		case "timeout_s":
			if v, ok := value.(float64); ok {
				if v < 1 {
					Error.Code = 1
					Error.Message = "Invalid parameter value : timeout_s cannot be less than 1"
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : timeout_s should be a number"
				break
			}
		default:
			Error.Code = 3
			Error.Message = "Invalid parameter name : " + paramName
			break
		}
	}
	return Error
}
