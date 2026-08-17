package services

import (
	"Code/models"
	"Code/probe/probe"
	"fmt"
	"log"
	"net"
	"strings"
	"time"
)

// TCPExecute establishes a TCP connection from the specified network interface to a destination address, sends the
// requested data and optionally waits for a response from the remote endpoint.
func TCPExecute(msgCommand models.MsgCommandRequest, p *probe.Probe) {
	log.Println("[TCP] Executing tcp request with the parameters :", msgCommand.Params)

	// Validate the TCP parameters
	Error := ValidateTCPParams(&msgCommand)
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

	// Extract parameters from the command payload
	sendInterface := msgCommand.Params["interface"].(string)
	sourceAddress := p.Network.GetListOfAddr(sendInterface)[0]
	sourceIP := strings.Split(sourceAddress, "/")[0]
	sourcePort := fmt.Sprintf("%.0f", msgCommand.Params["source-port"].(float64))
	destinationAddress := msgCommand.Params["destination-ip"].(string)
	destinationPort := fmt.Sprintf("%.0f", msgCommand.Params["destination-port"].(float64))
	dataString := msgCommand.Params["data"].(string)
	waitingResponse := msgCommand.Params["waiting-response"].(bool)

	// Resolve the local source address and port.
	addrSource, err := net.ResolveTCPAddr("tcp", sourceIP+":"+sourcePort)
	if err != nil {
		Error.Code = 70
		Error.Message = "[TCP] resolve address : failed to resolve source address :" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Resolve the destination address and port.
	addrDestination, err := net.ResolveTCPAddr("tcp", destinationAddress+":"+destinationPort)
	if err != nil {
		Error.Code = 70
		Error.Message = "[TCP] resolve address : failed to resolve destination address :" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Establish the TCP connection using the selected source address.
	conn, err := net.DialTCP("tcp", addrSource, addrDestination)
	if err != nil {
		Error.Code = 71
		Error.Message = "[TCP] Connection failed : Unable to establish connection :" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}
	defer conn.Close()

	// Send the requested data through the TCP connection.
	data := []byte(dataString)
	n, err := conn.Write(data)
	if err != nil {
		Error.Code = 72
		Error.Message = "[TCP] Write failed :" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}
	log.Println("[TCP] TCP request send successfully :", n)

	result := models.UdpTcpResult{}

	// Wait for a response from the remote endpoint if requested.
	if waitingResponse {
		// Limit the amount of time spent waiting for a response.
		err = conn.SetReadDeadline(time.Now().Add(5 * time.Second))
		if err != nil {
			Error.Code = 73
			Error.Message = "[TCP] Set read deadline failed :" + err.Error()
			return
		}
		// Allocate a buffer for the received data.
		buffer := make([]byte, 1024)

		// Read the response from the TCP connection.
		n, err = conn.Read(buffer)
		if err != nil {
			Error.Code = 74
			Error.Message = "[TCP] Reception failed :" + err.Error()
			p.SendErrorResponse(msgCommand.ID, Error)
			return
		}
		log.Println("[TCP] TCP reception successfully :", string(buffer[:n]))

		// Store the received response in the result.
		result = models.UdpTcpResult{
			Response: string(buffer[:n]),
		}
	}
	p.SendSuccessResponse(msgCommand.ID, result)
}

// ValidateTCPParams validates the TCP command parameters and returns an error if any parameter is invalid.
func ValidateTCPParams(msgCommand *models.MsgCommandRequest) models.ErrorInfo {
	Error := models.ErrorInfo{}

	requiredParams := []string{"interface", "source-port", "destination-ip", "destination-port", "data", "waiting-response"}

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
		case "source-port":
			if v, ok := value.(float64); ok {
				if v < 1 || v > 65535 {
					Error.Code = 1
					Error.Message = "Invalid parameter value : source-port should be a value between 1 and 65535"
					break
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : source-port should be a number"
				break
			}
		case "destination-ip":
			if v, ok := value.(string); ok {
				if v == "" {
					Error.Code = 1
					Error.Message = "Invalid parameter value : destination-ip cannot be empty"
					break
				} else {
					_, err := net.ResolveIPAddr("ip", v)
					if err != nil {
						Error.Code = 1
						Error.Message = "Invalid parameter value : destination-ip should be a valid IP address or hostname"
						break
					}
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : destination-ip should be a string"
				break
			}
		case "destination-port":
			if v, ok := value.(float64); ok {
				if v < 1 || v > 65535 {
					Error.Code = 1
					Error.Message = "Invalid parameter value : destination-port should be a value between 1 and 65535"
					break
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : destination-port should be a number"
				break
			}
		case "data":
			if _, ok := value.(string); ok {
				continue
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : data should be a string"
				break
			}
		case "waiting-response":
			if _, ok := value.(bool); ok {
				continue
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : waiting-response should be a boolean"
			}
		default:
			Error.Code = 3
			Error.Message = "Invalid parameter name : " + paramName
			break
		}
	}
	return Error
}
