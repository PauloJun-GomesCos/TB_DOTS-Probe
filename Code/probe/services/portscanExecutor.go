package services

import (
	"Code/models"
	"Code/probe/probe"
	"context"
	"fmt"
	"log"
	"net"

	"github.com/Ullaakut/nmap/v4"
)

// PortscanExecute executes a port scan on the specified target using the selected network interface and
// requested port range.
func PortscanExecute(msgCommand models.MsgCommandRequest, p *probe.Probe) {
	log.Println("[PORT SCAN] Executing port scan with the parameters :", msgCommand.Params)

	// Validate the port scan parameters.
	Error := ValidatePortscanParams(&msgCommand)
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

	// Notify the coordinator that the port scan has started.
	p.SendProcessingResponse(msgCommand.ID)

	// Extract the portscan parameters from the command payload.
	interfaceName := msgCommand.Params["interface"].(string)
	target := msgCommand.Params["target"].(string)
	ports := msgCommand.Params["ports"].(string)
	sV := msgCommand.Params["sV"].(bool)

	// Create the Nmap scanner with the target, ports and network interface.
	scanner, err := nmap.NewScanner(
		nmap.WithTargets(target),
		nmap.WithPorts(ports),
		nmap.WithInterface(interfaceName),
	)
	if err != nil {
		Error.Code = 30
		Error.Message = "Port scan initialization error : failed to initialize port scan with error: " + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Enable service and version detection if requested.
	if sV {
		scanner, err = scanner.AddOptions(nmap.WithServiceInfo())
		if err != nil {
			Error.Code = 32
			Error.Message = "Port scan option adding error : failed to add service info with error: " + err.Error()
			p.SendErrorResponse(msgCommand.ID, Error)
			return
		}
	}

	// Execute the port scan.
	result, err := scanner.Run(context.Background())
	if err != nil {
		// Nmap returns "exit status 1" for some invalid port specifications.
		if err.Error() == "exit status 1" {
			Error.Code = 1
			Error.Message = "Invalid parameter value : " + ports + " is not a valid value for ports"
		} else {
			Error.Code = 31
			Error.Message = "Port scan execution error : Failed to run port scan with error: " + err.Error()
		}
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	resultScan := models.PortScanResult{
		Ports: []string{},
	}

	// Process the scan results for each discovered host and port.
	for _, host := range result.Hosts {
		for _, port := range host.Ports {
			// Store whether the port is open or closed together with its protocol and detected service.
			if port.State.State == "open" {
				resultScan.Ports = append(resultScan.Ports, fmt.Sprint(port.ID, "/", port.Protocol, " open ", port.Service.Name))
			} else {
				resultScan.Ports = append(resultScan.Ports, fmt.Sprint(port.ID, "/", port.Protocol, " closed ", port.Service.Name))
			}
		}
	}

	p.SendSuccessResponse(msgCommand.ID, resultScan)
}

// ValidatePortscanParams validates the portscan command parameters and returns an error if any parameter is invalid.
func ValidatePortscanParams(msgCommand *models.MsgCommandRequest) models.ErrorInfo {
	Error := models.ErrorInfo{}

	requiredParams := []string{"interface", "target", "ports", "sV"}

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
		case "target":
			if v, ok := value.(string); ok {
				if v == "" {
					Error.Code = 1
					Error.Message = "Invalid parameter value : target cannot be empty"
					break
				} else {
					_, err := net.ResolveIPAddr("ip", v)
					if err != nil {
						Error.Code = 1
						Error.Message = "Invalid parameter value : target should be a valid IP address or hostname"
						break
					}
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : target should be a string"
				break
			}
		case "ports":
			if v, ok := value.(string); ok {
				if v == "" {
					Error.Code = 1
					Error.Message = "Invalid parameter value : ports cannot be empty"
					break
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : ports should be a string"
				break
			}
		case "sV":
			if _, ok := value.(bool); ok {
				continue
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : sV should be a bool"
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
