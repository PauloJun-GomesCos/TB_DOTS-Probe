package models

// Group defines the format to define a configuration group.
type Group struct {
	Key       string            `json:"key"`
	Label     string            `json:"label"`
	Icon      string            `json:"icon"`
	VisibleIf *VisibleCondition `json:"visible_if,omitempty"`
}

// VisibleCondition defines if the group is visible or not.
type VisibleCondition struct {
	Key   string `json:"key"`
	Value bool   `json:"value"`
}

// ConfigParams defines the format of the list of parameters.
type ConfigParams struct {
	Config []Param `json:"config"`
}

// Param defines the format of a configuration parameter with all the metadata necessary to his display in the web
// interface of the coordinator.
type Param struct {
	Key   string `json:"key"`
	Label string `json:"label"`
	Type  string `json:"type"`

	Value   any       `json:"value,omitempty"`
	Example any       `json:"example,omitempty"`
	Group   string    `json:"group,omitempty"`
	Min     int       `json:"min,omitempty"`
	Max     int       `json:"max,omitempty"`
	Unit    string    `json:"unit,omitempty"`
	Options []Options `json:"options,omitempty"`
}

// Capability defines the format of a capability with all the metadata necessary to his display in the web interface
// of the coordinator.
type Capability struct {
	Action      string            `json:"action"`
	Label       string            `json:"label"`
	Icon        string            `json:"icon"`
	Description string            `json:"description"`
	Params      []CapabilityParam `json:"params"`
	Expected    []Result          `json:"result"`
}

// CapabilityParam defines the format of a capability parameter with all the metadata necessary to his display in the
// web interface of the coordinator.
type CapabilityParam struct {
	Key   string `json:"key"`
	Label string `json:"label"`
	Type  string `json:"type"`

	Value   any       `json:"value,omitempty"`
	Example any       `json:"example,omitempty"`
	Min     int       `json:"min,omitempty"`
	Max     int       `json:"max,omitempty"`
	Unit    string    `json:"unit,omitempty"`
	Options []Options `json:"options,omitempty"`
}

// Result defines the format of a capability result.
type Result struct {
	Key string `json:"key"`
}

type Options struct {
	Value string `json:"value"`
	Label string `json:"label"`
}

type KeymapExample struct {
	Header map[string]string `json:"header"`
}

// MsgAnnounce defines the format of the announcement message sent in the probes/announce topic.
type MsgAnnounce struct {
	ProbeID         string       `json:"probe_id"`
	RequestID       *string      `json:"id"`
	Type            []string     `json:"type"`
	FirmwareVersion string       `json:"firmware_version"`
	Capabilities    []Capability `json:"capabilities"`
	ConfigGroups    []Group      `json:"config_groups"`
	ConfigParams    []Param      `json:"config"`
	Network         any          `json:"network"`
	Timestamp       int64        `json:"timestamp"`
}

// MsgStatus defines the format the status message sent in the probes/{probe_id}/status topic.
type MsgStatus struct {
	Name          string  `json:"name"`
	State         string  `json:"state"`
	Uptime        int     `json:"uptime_seconds"`
	CpuPercent    float64 `json:"cpu_percent"`
	MemoryPercent float64 `json:"memory_percent"`
	Temperature   float64 `json:"temperature"`
	Timestamp     int64   `json:"timestamp"`
}

// MsgLastWill defines the format of the message sent in the probes/{probe_id}/status topic.
type MsgLastWill struct {
	State string `json:"state"`
}

// MsgDiscoverRequest defines the format of the discovery message receive in the probes/discover topic.
type MsgDiscoverRequest struct {
	RequestID string `json:"id"`
}

// MsgConfigRequest defines the format of the configuration message receive in the probes/{probe_id}/control topic.
type MsgConfigRequest struct {
	ID     string         `json:"id"`
	Params map[string]any `json:"params"`
}

// MsgCommandRequest defines the format of the command message receive in the probes/{probe_id}/command topic.
type MsgCommandRequest struct {
	ID     string         `json:"id"`
	Action string         `json:"action"`
	Params map[string]any `json:"params"`
}

// MsgResponse defines the format of the response message sent in the probes/{probe_id}/response topic.
type MsgResponse struct {
	ID        string    `json:"id"`
	Status    string    `json:"status"`
	Error     ErrorInfo `json:"error"`
	Result    any       `json:"result"`
	Timestamp int64     `json:"timestamp"`
}

// ErrorInfo defines the format of the error sent in the response message.
type ErrorInfo struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

type ResultEmpty struct{}

// PingResult defines the format of the results obtain after the execution of a ping command.
type PingResult struct {
	PacketsSent       int     `json:"packets_sent"`
	PacketsReceived   int     `json:"packets_received"`
	PacketLossPercent float64 `json:"packet_loss_percent"`
	RTTMinMs          float64 `json:"rtt_min_ms"`
	RTTAvgMs          float64 `json:"rtt_avg_ms"`
	RTTMaxMs          float64 `json:"rtt_max_ms"`
}

// CaptureResult defines the format of the results obtain after the execution of a capture command.
type CaptureResult struct {
	PcapB64 string `json:"pcap_b64"`
}

// PortScanResult defines the format of the results obtain after the execution of a portscan command.
type PortScanResult struct {
	Ports []string `json:"ports"`
}

// HttpResult defines the format of the results obtain after the execution of an http command.
type HttpResult struct {
	Status      int               `json:"status"`
	StatusText  string            `json:"statusText"`
	HTTPVersion string            `json:"httpVersion"`
	Headers     map[string]string `json:"headers"`
	Content     HTTPContent       `json:"content"`
}

// HTTPContent defines the format of the content field of the mqtt response.
type HTTPContent struct {
	MimeType string `json:"mimeType"`
	Size     int    `json:"size"`
	Encoding string `json:"encoding"`
	Text     string `json:"text"`
}

// UdpTcpResult defines the format of the content field of the udp and tcp response.
type UdpTcpResult struct {
	Response string `json:"response"`
}

// UdpTcpServerResult defines the format of the content field of the udp and tcp echo servers response.
type UdpTcpServerResult struct {
	Response []string `json:"response"`
}
