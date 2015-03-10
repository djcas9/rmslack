package main

import (
	"fmt"
	"os"
	"sync"

	log "github.com/Sirupsen/logrus"
	"github.com/nlopes/slack"
	"gopkg.in/alecthomas/kingpin.v1"
)

const (
	Name        = "rmslack"
	Version     = "0.1.0"
	Description = "Remove all messages for a given Slack channel"
)

var (
	SlackToken = kingpin.Flag("token", "Slack account token.").Short('t').Required().String()
	Quiet      = kingpin.Flag("quiet", "Remove all output logging.").Short('q').Bool()
	Debug      = kingpin.Flag("debug", "Enable debug mode.").Bool()
)

func init() {
	kingpin.Version(Version)
	kingpin.Parse()

	log.SetOutput(os.Stderr)

	if *Debug {
		log.SetLevel(log.DebugLevel)
	} else {
		log.SetLevel(log.InfoLevel)
	}

	if *Quiet {
		log.SetLevel(log.FatalLevel)
	}

}

func main() {
	log.Infof("Initializing %s Version: %s.", Name, Version)

	api := slack.New(*SlackToken)

	params := slack.NewHistoryParameters()

	channels, err := api.GetChannels(true)

	if err != nil {
		log.Fatal(err)
	}

	log.Infof("Fetching channel list.\n")

	for i, channel := range channels {
		fmt.Printf("[%d] %s (%s)\n", i, channel.Name, channel.Id)
	}

	fmt.Println("\nWhich channel would you like to purge messages from?")

	var channel_id int
	if _, err := fmt.Scanf("%d", &channel_id); err != nil {
		log.Fatal(err)
	}

	if channel_id > len(channels) || channel_id < 0 {
		log.Error("The channel you selected is not a valid option.")
		os.Exit(1)
	}

	log.Infof("Fetching history for channel: %s", channels[channel_id].Name)

	DeleteChannelMessages(channels[channel_id].Id, api, params)
	log.Info("All Done!")
}

func DeleteChannelMessages(id string, api *slack.Slack, params slack.HistoryParameters) {
	history, err := api.GetChannelHistory(id, params)

	if err != nil {
		log.Fatal(err)
	}

	if len(history.Messages) <= 0 {
		return
	}

	log.Infof("Removing Next Message Batch. Size: %d", len(history.Messages))

	var wg sync.WaitGroup
	throttle := make(chan struct{}, 10)

	for _, msg := range history.Messages {

		wg.Add(1)
		throttle <- struct{}{}

		go func(timestamp string) {
			defer wg.Done()
			defer func() { <-throttle }()

			log.Debug("Deleting Message: ", timestamp)
			if _, _, err := api.DeleteMessage(id, timestamp); err != nil {
				log.Error(err)
			}
		}(msg.Timestamp)
	}

	wg.Wait()

	DeleteChannelMessages(id, api, params)
}
