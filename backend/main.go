package main

import (
  //"bytes"
  "encoding/json"
  "fmt"
  "github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
  "github.com/docker/docker/client"
	"github.com/streadway/amqp"
  "golang.org/x/net/context"
  "io"
  "os"
)

type ChannelQueues struct {
	CommandChannel *amqp.Channel
	LogChannel     *amqp.Channel
}

type SubmitRequest struct {
	Language string `json:"language"`
	Script   string `json:"script"`
	Username string `json:"username"`
}

func InitQueues() (*amqp.Channel, *amqp.Channel) {
	conn1, err := amqp.Dial("amqp://queue/")
	if err != nil {
		panic(err)
	}
	//defer conn.Close()
	commandChannel, err := conn1.Channel()
	if err != nil {
		panic(err)
	}
	//defer ch.Close()
  q, err := commandChannel.QueueDeclare(
		"commands",
		false,
		false,
		false,
		false,
		nil,
	)
  err = commandChannel.QueueBind(
    q.Name,
    "",
    "doggo",
    false,
    nil,
  )
	if err != nil {
		panic(err)
	}
	conn2, err := amqp.Dial("amqp://queue/")
	if err != nil {
		panic(err)
	}
	//defer conn.Close()
	logChannel, err := conn2.Channel()
	if err != nil {
		panic(err)
	}
	_, err = logChannel.QueueDeclare(
		"logs",
		false,
		false,
		false,
		false,
		nil,
	)
	if err != nil {
		panic(err)
	}
	return commandChannel, logChannel
}

func (queue *ChannelQueues) ListenForCommands() {
	commands, err := queue.LogChannel.Consume("commands", "", false, false, false, false, nil)
	if err != nil {
    panic(err)
		//return
	}
	go func() {
		for command := range commands {
      request := &SubmitRequest{}
      json.Unmarshal(command.Body, &request)
      fmt.Printf("got a command: %v", request)
      ctx := context.Background()
      //cli, err := client.NewEnvClient()
      cli, err := client.NewClient("http://10.0.2.15:2375", "", nil, nil)
      if err != nil {
        panic(err)
      }
      var img string
      switch request.Language {
      case "js":
        img = "node:latest"
      case "python":
        img = "python:latest"
      default:
        img = "ubuntu:latest"
      }
      resp, err := cli.ContainerCreate(ctx, &container.Config{
        Image: img,
        Cmd: []string{"/bin/bash", "-c", request.Script},
        Tty: false,
      }, nil, nil, "")
      if err != nil {
        panic(err)
      }
      if err := cli.ContainerStart(ctx, resp.ID, types.ContainerStartOptions{}); err != nil {
        panic(err)
      }
      statusCh, errCh := cli.ContainerWait(ctx, resp.ID, container.WaitConditionNotRunning)
      select {
      case err := <- errCh:
        if err != nil {
          panic(err)
        }
      case msg := <- statusCh:
        fmt.Printf("got a msg: %v", msg)
      }
      out, err := cli.ContainerLogs(ctx, resp.ID, types.ContainerLogsOptions{ShowStdout: true})
      if err != nil {
        panic(err)
      }
      fmt.Printf("got some output: %+v\n", out)
      _, err = io.Copy(os.Stdout, out)
      if err != nil {
        panic(err)
      }
		}
	}()
}

func main() {
  commandChannel, logChannel := InitQueues()
  queues := &ChannelQueues{
    CommandChannel: commandChannel,
    LogChannel:     logChannel,
  }
  go queues.ListenForCommands()
  fmt.Printf("got queues: %v", queues)
  select {}
}
