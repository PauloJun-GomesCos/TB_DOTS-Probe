package services

import (
	"Code/models"
	"Code/probe/probe"
	"log"
	"net"
	"time"

	"github.com/prometheus-community/pro-bing"
)

// PingExecute executes a ping using the specified interface and parameters, then sends the results.
func PingExecute(msgCommand models.MsgCommandRequest, p *probe.Probe) {
	log.Println("[PING] Executing ping with the parameters :", msgCommand.Params)

	// Validate the ping parameters.
	Error := ValidatePingParams(&msgCommand)
	if Error.Code != 0 {
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Check that the specified network interface exists actually on the probe.
	if !p.Network.CheckInterfaceExist(msgCommand.Params["interface"].(string)) {
		Error.Code = 1
		Error.Message = "Invalid parameter value : interface is unknown"
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Extract parameters from the command payload.
	interfaceName := msgCommand.Params["interface"].(string)
	target := msgCommand.Params["target"].(string)
	count := msgCommand.Params["count"].(float64)
	timeout := msgCommand.Params["timeout_ms"].(float64)

	// Create a new pinger instance for the target host.
	pinger, err := probing.NewPinger(target)
	if err != nil {
		Error.Code = 10
		Error.Message = "Ping initialization error : Failed to initialize ping for target " + target + " with error: " + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Configure ping settings.
	pinger.Count = int(count)
	pinger.Interval = 100 * time.Millisecond
	pinger.Timeout = time.Duration(timeout) * time.Millisecond
	pinger.InterfaceName = interfaceName
	pinger.SetPrivileged(true)

	var result models.PingResult

	// Callback executed when ping finishes.
	pinger.OnFinish = func(stats *probing.Statistics) {
		result = models.PingResult{
			PacketsSent:       stats.PacketsSent,
			PacketsReceived:   stats.PacketsRecv,
			PacketLossPercent: stats.PacketLoss,
			RTTMinMs:          float64(stats.MinRtt) / float64(time.Millisecond),
			RTTAvgMs:          float64(stats.AvgRtt) / float64(time.Millisecond),
			RTTMaxMs:          float64(stats.MaxRtt) / float64(time.Millisecond),
		}
	}

	// Run the ping operation.
	err = pinger.Run()
	if err != nil {
		Error.Code = 11
		Error.Message = "Ping execution error : Failed to run ping for target " + target + " with error: " + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Return collected results.
	p.SendSuccessResponse(msgCommand.ID, result)
}

// ValidatePingParams validates the ping command parameters and returns an error if any parameter is invalid.
func ValidatePingParams(msgCommand *models.MsgCommandRequest) models.ErrorInfo {
	Error := models.ErrorInfo{}

	requiredParams := []string{"interface", "target", "count", "timeout_ms"}

	// Check missing params
	for _, param := range requiredParams {
		if _, exists := msgCommand.Params[param]; !exists {
			Error.Code = 4
			Error.Message = "Missing parameter: The parameter " + param + " is required to execute the ping command"
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
		case "count":
			if v, ok := value.(float64); ok {
				if v < 1 {
					Error.Code = 1
					Error.Message = "Invalid parameter value : count cannot be less than 1"
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : count should be a number"
				break
			}
		case "timeout_ms":
			if v, ok := value.(float64); ok {
				if v < 1 {
					Error.Code = 1
					Error.Message = "Invalid parameter value : timeout_ms cannot be less than 1"
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : timeout_ms should be a number"
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
