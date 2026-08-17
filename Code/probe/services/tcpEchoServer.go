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

// TCPServerEchoExecute starts a TCP echo server on the specified network interface and port.
// Received messages are stored and echoed back to the connected clients until the configured timeout is reached.
func TCPServerEchoExecute(msgCommand models.MsgCommandRequest, p *probe.Probe) {
	log.Println("[TCP ECHO SERVER] Executing tcp echo server with the parameters :", msgCommand.Params)

	// Validate the TCP server parameters
	Error := ValidateTCPServerParams(&msgCommand)
	if Error.Code != 0 {
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Check that the specified network interface exists actually on the probe
	if !p.Network.CheckInterfaceExist(msgCommand.Params["interface"].(string)) {
		Error.Code = 1
		Error.Message = "Invalid parameter value : interface is unknown"
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Extract parameters from the command payload.
	sendInterface := msgCommand.Params["interface"].(string)
	sourceAddress := p.Network.GetListOfAddr(sendInterface)[0]
	sourceIP := strings.Split(sourceAddress, "/")[0]
	sourcePort := fmt.Sprintf("%.0f", msgCommand.Params["port"].(float64))
	timeoutSeconde := time.Duration(msgCommand.Params["timeout_s"].(float64)) * time.Second

	// Create the TCP address using the selected interface IP and port.
	addr, err := net.ResolveTCPAddr("tcp", sourceIP+":"+sourcePort)
	if err != nil {
		Error.Code = 80
		Error.Message = "[TCP ECHO SERVER] Error resolving source address :" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Create the TCP listener.
	log.Println("[TCP ECHO SERVER] TCP echo server started")
	log.Println("[TCP ECHO SERVER] TCP server listening on", addr.String())
	listener, err := net.ListenTCP("tcp", addr)
	if err != nil {
		Error.Code = 81
		Error.Message = "[TCP ECHO SERVER] Error creating the TCP listener" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Ensure the TCP listener is closed when the function returns
	defer func(listener *net.TCPListener) {
		err = listener.Close()
		if err != nil {
			Error.Code = 82
			Error.Message = "[TCP ECHO SERVER] Error closing the TCP listener" + err.Error()
			p.SendErrorResponse(msgCommand.ID, Error)
		}
	}(listener)

	// Notify the coordinator that the TCP server is ready and processing.
	p.SendProcessingResponse(msgCommand.ID)

	result := models.UdpTcpServerResult{
		Response: []string{},
	}

	// Allocate a buffer used to receive data from TCP clients.
	buffer := make([]byte, 1024)

	// Create a timer that determines how long the server remains active.
	timer := time.NewTimer(timeoutSeconde)

	// Close the listener when the timeout expires. Closing the listener causes Accept() to return an error, which
	// allows the main loop to stop the server.
	go func() {
		<-timer.C
		err = listener.Close()
		if err != nil {
			return
		}
	}()

	for {
		// Wait for an incoming TCP connection.
		conn, err := listener.Accept()
		if err != nil {
			log.Println("[TCP ECHO SERVER] Accept error:", err)

			// A closed listener indicates that the configured timeout has expired and the server must stop.
			if errors.Is(err, net.ErrClosed) {
				log.Println("[TCP ECHO SERVER] TCP echo server stopped by the timeoutSec")
				p.SendSuccessResponse(msgCommand.ID, result)
				break
			}
			return
		}

		// Read the message sent by the TCP client.
		n, err := conn.Read(buffer)
		if err != nil {
			log.Println("[TCP ECHO SERVER] Accept error:", err)

			// Check if the connection was closed because the server timeout was reached.
			if errors.Is(err, net.ErrClosed) {
				log.Println("[TCP ECHO SERVER] TCP echo server stopped by the timer")
				p.SendSuccessResponse(msgCommand.ID, result)
				break
			}
			return
		}
		log.Println("[TCP ECHO SERVER] Received message from client:", string(buffer[:n]))

		// Store the received message in the result.
		result.Response = append(result.Response, string(buffer[:n]))

		// Echo the received message back to the TCP client.
		log.Println("[TCP ECHO SERVER] Writing back the message to the client:", string(buffer[:n]))
		_, err = conn.Write(buffer[:n])
		if err != nil {
			Error.Code = 83
			Error.Message = "[TCP ECHO SERVER] Error writing:" + err.Error()
			p.SendErrorResponse(msgCommand.ID, Error)
			return
		}

		// Close the client connection after sending the response.
		err = conn.Close()
		if err != nil {
			return
		}
	}
}

// ValidateTCPServerParams validates the TCP echo server command parameters and returns an error if any parameter is invalid.
func ValidateTCPServerParams(msgCommand *models.MsgCommandRequest) models.ErrorInfo {
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
