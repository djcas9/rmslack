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
	name        = "rmslack"
	version     = "0.1.1"
	description = "Remove all messages for a given Slack channel"
)

var (
	slackToken = kingpin.Flag("token", "Slack account token.").Short('t').Required().String()
	quiet      = kingpin.Flag("quiet", "Remove all output logging.").Short('q').Bool()
	debug      = kingpin.Flag("debug", "Enable debug mode.").Bool()
)

func init() {
	kingpin.Version(version)
	kingpin.Parse()

	log.SetOutput(os.Stderr)

	if *debug {
		log.SetLevel(log.DebugLevel)
	} else {
		log.SetLevel(log.InfoLevel)
	}

	if *quiet {
		log.SetLevel(log.FatalLevel)
	}

}

func main() {
	log.Infof("Initializing %s Version: %s.", name, version)

	api := slack.New(*slackToken)

	params := slack.NewHistoryParameters()

	channels, err := api.GetChannels(true)

	if err != nil {
		log.Fatal(err)
	}

	log.Infof("Fetching channel list.\n")

	for i, channel := range channels {
		fmt.Printf("[%d] %s (%s)\n", i, channel.Name, channel.ID)
	}

	fmt.Println("\nWhich channel would you like to purge messages from?")

	var channelID int
	if _, err := fmt.Scanf("%d", &channelID); err != nil {
		log.Fatal(err)
	}

	if channelID > len(channels) || channelID < 0 {
		log.Error("The channel you selected is not a valid option.")
		os.Exit(1)
	}

	log.Infof("Fetching history for channel: %s", channels[channelID].Name)

	deleteChannelMessages(channels[channelID].ID, api, params)
	log.Info("All Done!")
}

func deleteChannelMessages(id string, api *slack.Client, params slack.HistoryParameters) {
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

	deleteChannelMessages(id, api, params)
}
