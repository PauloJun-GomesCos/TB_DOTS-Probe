package status

import (
	"Code/probe/config"
	"Code/probe/probe"
	"context"
	"log"
	"time"
)

// SendStatus periodically sends the current status of the probe. The sending interval can be dynamically updated
// through updateCh. The status goroutine stops when the provided context is cancelled.
func SendStatus(ctx context.Context, updateCh chan config.ProbeConfigParams, probe *probe.Probe) {
	// Send the initial status immediately when the function starts.
	probe.SendMsgStatus()

	// Get the initial status sending interval from the probe configuration.
	currentInterval := probe.ProbeConfig.StatusInterval

	// Create a ticker to periodically trigger status messages.
	ticker := time.NewTicker(time.Duration(currentInterval) * time.Second)
	defer ticker.Stop()

	// Continuously wait for an interval update, a ticker event, or a cancellation of the context.
	for {
		select {
		// A new configuration has been received through the update channel.
		case update := <-updateCh:
			currentInterval = update.StatusInterval

			// Stop the previous ticker before creating a new one.
			ticker.Stop()
			ticker = time.NewTicker(time.Duration(currentInterval) * time.Second)

			// Send the status immediately after applying the new interval.
			probe.SendMsgStatus()

		// The channel ticker.C changed (tick end)
		case <-ticker.C:
			// Send the current probe status.
			probe.SendMsgStatus()

		// The context has been cancelled, so stop the status goroutine.
		case <-ctx.Done():
			log.Println("[STATUS]Status goroutine stopped")
			return
		}
	}
}
