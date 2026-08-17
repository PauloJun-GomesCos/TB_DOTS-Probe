package probe

import (
	"Code/models"
	"encoding/json"
	"log"
)

// HandleCommand processes command messages received through the probes/{probe_id}/command topic.
func (p *Probe) HandleCommand(payload string) {
	log.Printf("[COMMAND handler] Receive a command message with the payload : [%s]", payload)

	// Parse the received command payload.
	msgCommand, Error := ParseCommandMessage(payload)

	// Stop processing if the command payload is invalid.
	if Error.Code != 0 {
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	/// Reject commands when the probe is disabled.
	if p.ProbeConfig.Enabled == false {
		p.SendErrorResponse(msgCommand.ID, models.ErrorInfo{Code: 5, Message: "Probe is disabled"})
		return
	}

	// Validate the command parameters and check that the requested action is supported by the probe.
	Error = ValidateCommandParams(&msgCommand, p.Executors)
	if Error.Code != 0 {
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Execute the requested command asynchronously so that the MQTT message handler is not blocked while the
	// command is running.
	go func() {
		p.Executors[msgCommand.Action](msgCommand, p)
	}()
}

// ParseControlMessage parses the JSON payload of a control message and returns the decoded message together with any parsing error
func ParseCommandMessage(payload string) (models.MsgCommandRequest, models.ErrorInfo) {
	Error := models.ErrorInfo{}
	var msgCommand models.MsgCommandRequest

	// Decode the JSON payload into the configuration message structure.
	err := json.Unmarshal([]byte(payload), &msgCommand)
	if err != nil {
		switch e := err.(type) {
		case *json.SyntaxError:
			// Return an error when the payload contains invalid JSON syntax
			Error.Code = 99
			Error.Message = "Syntax error"
			return msgCommand, Error
		case *json.UnmarshalTypeError:
			// Return an error when a parameter has an incompatible data type
			Error.Code = 2
			Error.Message = "Invalid parameter format : " + e.Field + " should be " + e.Type.String()
			return msgCommand, Error
		default:
			log.Println("Other error:", err)
			return msgCommand, Error
		}
	}

	return msgCommand, Error
}

// ValidateCommandParams validates the command parameters sent in the configuration message
func ValidateCommandParams(msgCommand *models.MsgCommandRequest, listParam map[string]func(models.MsgCommandRequest, *Probe)) models.ErrorInfo {
	Error := models.ErrorInfo{}

	if msgCommand.ID == "" {
		Error.Code = 1
		Error.Message = "Invalid parameter value : id cannot be empty"
		return Error
	}

	if msgCommand.Action == "" {
		Error.Code = 1
		Error.Message = "Invalid parameter value : action cannot be empty"
		return Error
	}

	// Check whether the requested action is registered in the list of available command.
	for param := range listParam {
		if msgCommand.Action == param {
			Error = models.ErrorInfo{}
			return Error
		}
	}
	Error.Code = 3
	Error.Message = "Invalid parameter name : action " + msgCommand.Action + " is unknown"

	return Error
}
