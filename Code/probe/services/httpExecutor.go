package services

import (
	"Code/models"
	"Code/probe/probe"
	"bytes"
	"encoding/base64"
	"io"
	"log"
	"net"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"
)

// HTTPExecute executes an HTTP request using the specified network interface.
// The interface IP address is used as the local source address for the request.
// The HTTP response is then returned to the coordinator.
func HTTPExecute(msgCommand models.MsgCommandRequest, p *probe.Probe) {
	log.Println("[HTTP] Executing http request with the parameters :", msgCommand.Params)

	// Validate the HTTP request parameters.
	Error := ValidateHTTPRequestParams(&msgCommand)
	if Error.Code != 0 {
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Check that the requested network interface currently exists on the probe.
	if !p.Network.CheckInterfaceExist(msgCommand.Params["interface"].(string)) {
		Error.Code = 1
		Error.Message = "Invalid parameter value : interface is unknown"
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Extract the HTTP request parameters from the command payload.
	interfaces := msgCommand.Params["interface"].(string)
	method := msgCommand.Params["method"].(string)
	header, headerPresent := msgCommand.Params["header"].(map[string]any)
	url := msgCommand.Params["url"].(string)
	body, bodyPresent := msgCommand.Params["body"].(map[string]any)

	// Retrieve the IP addresses configured on the selected interface.
	listIP := p.Network.GetListOfAddr(interfaces)

	// Extract the IP address without its subnet prefix.
	ipStr := strings.Split(listIP[0], "/")[0]
	localAddr := &net.TCPAddr{
		IP: net.ParseIP(ipStr),
	}
	log.Println("[HTTP] the ip of the interface is ", localAddr.String())

	// Create a network dialer using the selected interface IP as the source address. This ensures that the HTTP
	// request is sent through the requested network interface.
	dialer := &net.Dialer{
		LocalAddr: localAddr,
		Timeout:   5 * time.Second,
	}

	// Configure the HTTP transport to use the custom network dialer.
	transport := &http.Transport{
		DialContext: dialer.DialContext,
	}

	// Create an HTTP client using the custom transport.
	client := &http.Client{
		Transport: transport,
	}

	// Prepare the request body.
	var bodyReader io.Reader

	if bodyPresent {
		switch body["type"].(string) {
		// JSON and text bodies are directly converted into readers.
		case "json":
			bodyReader = strings.NewReader(body["data"].(string))
		case "text":
			bodyReader = strings.NewReader(body["data"].(string))
		// File bodies are received as Base64 and decoded before being sent.
		case "file":
			data, err := base64.StdEncoding.DecodeString(body["data"].(string))
			if err != nil {
				Error.Code = 40
				Error.Message = "Failed to decode the base64 file :" + err.Error()
				p.SendErrorResponse(msgCommand.ID, Error)
				return
			}
			bodyReader = bytes.NewReader(data)
		}
	}

	// Create the HTTP request using the requested method, URL and body.
	req, err := http.NewRequest(method, url, bodyReader)
	if err != nil {
		Error.Code = 41
		Error.Message = "Error creating http request :" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}

	// Add the requested HTTP headers to the request.
	if headerPresent {
		for k, v := range header {
			req.Header.Add(k, v.(string))
		}
	}

	// Send the HTTP request.
	resp, err := client.Do(req)
	if err != nil {
		Error.Code = 41
		Error.Message = "Error sending http request :" + err.Error()
		p.SendErrorResponse(msgCommand.ID, Error)
		return
	}
	// Ensure that the response body is closed when the function returns.
	defer resp.Body.Close()

	// Convert the HTTP response headers into a string map.
	headerResponse := make(map[string]string)

	for k, v := range resp.Header {
		headerResponse[k] = v[0]
	}

	// Create the response content structure.
	content := models.HTTPContent{
		MimeType: resp.Header.Get("Content-Type"),
	}

	// Read the response body as raw bytes. This allows both textual and binary responses to be handled.
	data, _ := io.ReadAll(resp.Body)

	// If the response contains valid UTF-8 data, return it as text. Otherwise, encode the binary data using Base64.
	if utf8.Valid(data) {
		content.Size = len(data)
		content.Encoding = "utf-8"
		content.Text = string(data)
	} else {
		content.Size = len(data)
		content.Encoding = "base64"
		content.Text = base64.StdEncoding.EncodeToString(data)
	}

	// Build the HTTP result returned to the coordinator.
	result := models.HttpResult{
		Status:      resp.StatusCode,
		StatusText:  resp.Status,
		HTTPVersion: resp.Proto,
		Headers:     headerResponse,
		Content:     content,
	}

	// Treat successful HTTP responses as successful command executions.
	if resp.StatusCode == 200 || resp.StatusCode == 201 {
		p.SendSuccessResponse(msgCommand.ID, result)
	} else {
		// Return the HTTP status as an error for other response codes.
		Error.Code = resp.StatusCode
		Error.Message = resp.Status
		p.SendErrorResponse(msgCommand.ID, Error)
	}
}

// ValidateHTTPRequestParams validates the HTTP request command parameters and returns an error if any parameter is invalid.
func ValidateHTTPRequestParams(msgCommand *models.MsgCommandRequest) models.ErrorInfo {
	Error := models.ErrorInfo{}

	requiredParams := []string{"interface", "method", "url"}

	// Check missing params
	for _, param := range requiredParams {
		if _, exists := msgCommand.Params[param]; !exists {
			Error.Code = 4
			Error.Message = "Missing parameter: The parameter " + param + " is required to execute the port scan command"
			return Error
		}
	}

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
		case "method":
			if v, ok := value.(string); ok {
				if v == "" {
					Error.Code = 1
					Error.Message = "Invalid parameter value : method cannot be empty"
					break
				} else {
					if !isValidMethod(v) {
						Error.Code = 1
						Error.Message = "Invalid parameter value : method is not supported, only supported method are GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS"
						break
					}
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : method should be a string"
				break
			}
		case "header":

		case "url":
			if v, ok := value.(string); ok {
				if v == "" {
					Error.Code = 1
					Error.Message = "Invalid parameter value : url cannot be empty"
					break
				}
			} else {
				Error.Code = 2
				Error.Message = "Invalid parameter format : url should be a string"
				break
			}
		case "body":
			// The body must be provided as a map containing the body type and its corresponding data.
			body, ok := value.(map[string]any)
			if !ok {
				Error.Code = 2
				Error.Message = "Invalid parameter format : body should be a map"
				break
			} else {
				// Validate the body type.
				bodyType, ok := body["type"].(string)
				if !ok {
					Error.Code = 2
					Error.Message = "Invalid parameter format : body.type should be a string"
					break
				} else {
					if bodyType == "" {
						Error.Code = 1
						Error.Message = "Invalid parameter value : body.type cannot be empty"
						break
					} else if bodyType != "json" && bodyType != "text" && bodyType != "file" {
						Error.Code = 1
						Error.Message = "Invalid parameter value : body.type unknown it should be a json, text or file"
						break
					}
				}
				// Validate the body data.
				bodyData, ok := body["data"].(string)
				if !ok {
					Error.Code = 2
					Error.Message = "Invalid parameter format : body.data should be a string"
					break
				} else {
					if bodyData == "" {
						Error.Code = 1
						Error.Message = "Invalid parameter value : body.data cannot be empty"
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

// isValidMethod checks whether the provided HTTP method is supported by the HTTP service.
func isValidMethod(method string) bool {
	methods := []string{
		http.MethodGet,
		http.MethodPost,
		http.MethodPut,
		http.MethodDelete,
		http.MethodPatch,
		http.MethodHead,
		http.MethodOptions,
	}

	// Compare the requested method with each supported method.
	for _, m := range methods {
		if method == m {
			return true
		}
	}

	return false
}
