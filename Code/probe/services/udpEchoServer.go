package services

import (
	"Code/models"
	"Code/probe/probe"
	"errors"
	"fmt"
	"log"
	"net"
	"strings"
	"time"
)

// UDPServerEchoExecute starts a UDP echo server on the specified network interface and port. Received messages
// are stored and echoed back to the corresponding clients until the configured timeout is reached.
func UDPServerEchoExecute(msgCommand models.MsgCommandRequest, p *probe.Probe) {
	log.Println("[UDP ECHO SERVER] Executing udp echo server with the parameters :", msgCommand.Params)

	// Validate the UDP server parameters received from the coordinator.
	Error := ValidateUDPServerParams(&msgCommand)
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

	// Extract the UDP echo server parameters from the command payload.
	sendInterface := msgCommand.Params["interface"].(string)
	sourceAddress := p.Network.GetListOfAddr(sendInterface)[0]
	sourceIP := strings.Split(sourceAddress, "/")[0]
	sourcePort := fmt.Sprintf("%.0f", msgCommand.Params["port"].(float64))
	timeoutSecond := time.Duration(msgCommand.Params["timeout_s"].(float64)) * time.Second

	// Create the UDP address using the selected interface IP and port.
	addr, err := net.ResolveUDPAddr("udp", sourceIP+":"+sourcePort)
	if err != nil {
		Error.Code = 60
		Error.Message = "[UDP ECHO SERVER] Error resolving source address :" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Start the UDP listener.
	log.Println("[UDP ECHO SERVER] UDP echo server started")
	log.Println("[UDP ECHO SERVER] UDP server listening on", addr.String())
	conn, err := net.ListenUDP("udp", addr)
	if err != nil {
		Error.Code = 61
		Error.Message = "[UCP ECHO SERVER] Error creating the UDP listener" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}
	defer conn.Close()

	// Notify the coordinator that the UDP server is ready and processing.
	p.SendProcessingResponse(msgCommand.ID)

	result := models.UdpTcpServerResult{
		Response: []string{},
	}

	// Allocate a buffer for incoming UDP datagrams.
	buffer := make([]byte, 1024)

	// Create a timer that determines how long the server remains active.
	timer := time.NewTimer(timeoutSecond)

	// Close the UDP connection when the timeout expires.
	// This causes ReadFromUDP() to return and allows the server loop to stop.
	go func() {
		<-timer.C
		err = conn.Close()
		if err != nil {
			return
		}
	}()

	for {
		// Wait for an incoming UDP datagram.
		n, clientAddr, err := conn.ReadFromUDP(buffer)
		if err != nil {
			log.Println("[UDP ECHO SERVER] Accept error:", err)

			// A closed listener indicates that the configured timeout has expired and the server must stop.
			if errors.Is(err, net.ErrClosed) {
				log.Println("[UDP ECHO SERVER] UDP echo server stopped by the timeout")
				p.SendSuccessResponse(msgCommand.ID, result)
				break
			}

			Error.Code = 63
			Error.Message = "[UDP ECHO SERVER] Reception failed: " + err.Error()
			p.SendErrorResponse(msgCommand.ID, Error)
			return
		}
		log.Println("[UDP ECHO SERVER] Received message from client:", string(buffer[:n]))

		// Store the received message in the result.
		result.Response = append(result.Response, string(buffer[:n]))

		// Echo the received datagram back to the client that sent it.
		log.Println("[UDP ECHO SERVER] Writing back the message to the client:", string(buffer[:n]))
		_, err = conn.WriteToUDP(buffer[:n], clientAddr)
		if err != nil {
			Error.Code = 64
			Error.Message = "[UDP ECHO SERVER] Error writing:" + err.Error()
			p.SendErrorResponse(msgCommand.ID, Error)
			return
		}
	}
}

// ValidateUDPServerParams validates the UDP echo server command parameters and returns an error if any parameter is invalid.
func ValidateUDPServerParams(msgCommand *models.MsgCommandRequest) models.ErrorInfo {
	Error := models.ErrorInfo{}

	requiredParams := []string{"interface", "port", "timeout_s"}

	// Check missing params
	for _, param := range requiredParams {
		if _, exists := msgCommand.Params[param]; !exists {
			Error.Code = 4
			Error.Message = "Missing parameter: The parameter " + param + " is required to execute the port scan command"
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
		case "port":
			if v, ok := value.(float64); ok {
				if v < 1 || v > 65535 {
					Error.Code = 1
					Error.Message = "Invalid parameter value : port should be a value between 1 and 65535"
					break
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : port should be a number"
				break
			}
		case "timeout_s":
			if v, ok := value.(float64); ok {
				if v < 1 {
					Error.Code = 1
					Error.Message = "Invalid parameter value : timeout_s cannot be less than 1"
					break
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
