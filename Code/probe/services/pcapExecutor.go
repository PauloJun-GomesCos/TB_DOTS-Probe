package services

import (
	"Code/models"
	"Code/probe/probe"
	"encoding/base64"
	"io"
	"log"
	"os"
	"time"

	"github.com/gopacket/gopacket/pcap"
)

// PcapExecute replays the packets contained in a PCAP file on the specified network interface while preserving the
// original packet timing.
func PcapExecute(msgCommand models.MsgCommandRequest, p *probe.Probe) {
	log.Println("[PCAP] Executing pcap file with the parameters :", msgCommand.Params)

	// Validate the parameters received from the coordinator.
	Error := ValidatePcapParams(&msgCommand)
	if Error.Code != 0 {
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Check that the specified network interface currently exists on the probe.
	if !p.Network.CheckInterfaceExist(msgCommand.Params["interface"].(string)) {
		Error.Code = 1
		Error.Message = "Invalid parameter value : interface is unknown"
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Extract the PCAP command parameters from the command payload.
	interfaceName := msgCommand.Params["interface"].(string)
	filter := msgCommand.Params["filter"].(string)
	file := msgCommand.Params["file"].(map[string]any)
	fileData := file["data"].(string)

	// Decode the Base64-encoded PCAP file received from the coordinator.
	pcapFile, err := base64.StdEncoding.DecodeString(fileData)
	if err != nil {
		Error.Code = 90
		Error.Message = "Failed to decode the received pcap file:" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Create a temporary PCAP file.
	// pcap.OpenOffline() requires a file containing the PCAP data.
	f, err := os.Create("capture_received.pcap")
	if err != nil {
		Error.Code = 91
		Error.Message = "Failed to create the temporary pcap file:" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}
	defer f.Close()

	// Write all the packet of the pcap file received in the pcap file created
	if _, err = f.Write(pcapFile); err != nil {
		Error.Code = 92
		Error.Message = "Failed to write in the temporary pcap file:" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Flush written data to ensure the pcap file is fully saved before reading it.
	if err = f.Sync(); err != nil {
		Error.Code = 93
		Error.Message = "Failed to flush temporary pcap file:" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Open the temporary PCAP file as the source of packets. (All returned timestamps are scaled to nanosecond resolution)
	handle, err := pcap.OpenOffline("capture_received.pcap")
	if err != nil {
		Error.Code = 94
		Error.Message = "Failed to open the temporary pcap file:" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}
	defer handle.Close()

	// Open the target network interface for packet transmission.
	outHandle, err := pcap.OpenLive(interfaceName, 65535, true, pcap.BlockForever)
	if err != nil {
		Error.Code = 95
		Error.Message = "Failed to open a capture session with error:" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}
	defer outHandle.Close()

	// Apply the BPF filter to select which packets from the PCAP file should be replayed.
	err = handle.SetBPFFilter(filter)
	if err != nil {
		Error.Code = 1
		Error.Message = "Invalid parameter value: " + filter + " is not a valid BPF filter"
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Store the timestamp of the first packet and the local time at which the replay starts. These values are used
	// to preserve the original timing between packets.
	firstTimestamp := time.Time{}
	var startTime time.Time

	for {
		// Read the next packet and its capture metadata from the PCAP file.
		data, ci, err := handle.ReadPacketData()

		// End of file means that all packets have been replayed.
		if err == io.EOF {
			log.Println("[PCAP] No more packet to read")
			p.SendSuccessResponse(msgCommand.ID, models.ResultEmpty{})
			return
		}

		// Handle errors encountered while reading the PCAP file.
		if err != nil {
			Error.Code = 96
			Error.Message = "Failed to read the packet data:" + err.Error()
			p.SendErrorResponse(msgCommand.ID, Error)
			return
		}

		// Initialize the replay reference time using the timestamp of the first packet
		if firstTimestamp.IsZero() {
			firstTimestamp = ci.Timestamp
			startTime = time.Now()
		}

		// Theoretical time when this packet is scheduled to be sent
		expected := startTime.Add(ci.Timestamp.Sub(firstTimestamp))

		// Wait until the scheduled time
		if wait := time.Until(expected); wait > 0 {
			time.Sleep(wait)
		}

		// Transmit the packet through the selected network interface.
		err = outHandle.WritePacketData(data)
		if err != nil {
			Error.Code = 97
			Error.Message = "Failed to write the packet data:" + err.Error()
			p.SendErrorResponse(msgCommand.ID, Error)
			return
		}
	}
}

// ValidatePcapParams validates the PCAP command parameters and returns an error if any parameter is invalid.
func ValidatePcapParams(msgCommand *models.MsgCommandRequest) models.ErrorInfo {
	Error := models.ErrorInfo{}

	requiredParams := []string{"interface", "filter", "file"}

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
		case "file":
			file, ok := value.(map[string]any)
			// The file must be provided as a map containing the data and the file name.
			if !ok {
				Error.Code = 2
				Error.Message = "Invalid parameter format : body should be a map"
				break
			} else {
				// Validate the file data.
				fileData, ok := file["data"].(string)
				if !ok {
					Error.Code = 2
					Error.Message = "Invalid parameter format : file.data should be a string"
					break
				} else {
					if fileData == "" {
						Error.Code = 1
						Error.Message = "Invalid parameter value : file.data cannot be empty"
						break
					}
				}
				// Validate the file name.
				fileName, ok := file["name"].(string)
				if !ok {
					Error.Code = 2
					Error.Message = "Invalid parameter format : file.name should be a string"
					break
				} else {
					if fileName == "" {
						Error.Code = 1
						Error.Message = "Invalid parameter value : file.name cannot be empty"
						break
					}
				}
			}
		default:
			Error.Code = 3
			Error.Message = "Invalid parameter name : " + paramName
			break
		}
	}
	return Error
}
