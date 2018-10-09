package main

import (
  "encoding/json"
  "fmt"
  "github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
  "github.com/docker/docker/client"
	"github.com/streadway/amqp"
  "golang.org/x/net/context"
  "io/ioutil"
  "strings"
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

type ContainerLog struct {
	Username string `json:"username"`
	Log      string `json:"log"`
}

var channelQueue *ChannelQueues

func (r *SubmitRequest) GetScript() string {
  script := strings.Replace(r.Script, "\"", "\\\"", -1)
  script = strings.Replace(script, "`", "\\\\`", -1)
  switch(r.Language) {
  case "js":
    return fmt.Sprintf("/bin/echo \"%s\" > runner.js && node runner.js", script)
  case "py":
    return fmt.Sprintf("/bin/echo \"%s\" > runner.py && python runner.py", script)
  default:
    return ">&2 /bin/echo File extension not supported."
  }
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
  _, err = commandChannel.QueueDeclare(
    "commands",
    false,
    false,
    false,
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

func (queue *ChannelQueues) SendLogs(submission []byte) {
	err := queue.LogChannel.Publish(
		"",
		"logs",
		false,
		false,
		amqp.Publishing{
			ContentType: "application/json",
			Body:        submission,
		},
	)
	if err != nil {
    panic(err)
		//return
	}
}

func (queue *ChannelQueues) ListenForCommands() {
	commands, err := queue.CommandChannel.Consume("commands", "", false, false, false, false, nil)
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
      case "py":
        img = "python:latest"
      default:
        img = "ubuntu:latest"
      }
      resp, err := cli.ContainerCreate(ctx, &container.Config{
        Image: img,
        //Cmd: []string{"/bin/bash", "-c", request.Script},
        Cmd: []string{"/bin/sh", "-c", request.GetScript()},
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
      reader, err := cli.ContainerLogs(ctx, resp.ID, types.ContainerLogsOptions{ShowStderr: true, ShowStdout: true, Follow: true})
      if err != nil {
        panic(err)
      }
      defer reader.Close()
      p := make([]byte, 8)
      reader.Read(p)
      content, _ := ioutil.ReadAll(reader)
      fmt.Printf("container log: %s", string(content))
      log := &ContainerLog{
        Username: "test",
        Log: string(content),
      }
      response, err := json.Marshal(log)
      channelQueue.SendLogs([]byte(response))
		}
	}()
}

func main() {
  commandChannel, logChannel := InitQueues()
  channelQueue = &ChannelQueues{
    CommandChannel: commandChannel,
    LogChannel:     logChannel,
  }
  go channelQueue.ListenForCommands()
  fmt.Printf("got queues: %v", channelQueue)
  select {}
}
