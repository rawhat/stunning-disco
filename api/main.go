package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	_ "github.com/lib/pq"
	"github.com/streadway/amqp"
)

type ChannelQueues struct {
	CommandChannel *amqp.Channel
	LogChannel     *amqp.Channel
}

type Database struct {
	db *sql.DB
}

func SayHello(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Hello world!"))
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type Response struct {
	Status  int    `json:"status"`
	Message string `json:"message"`
}

type WebsocketMessage struct {
	Action  string `json:"action"`
	Message interface{}
}

type WebsocketRegister struct {
	Username string `json:"username"`
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
var database *Database
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		// TODO:  fix me, obvi
		return true
	},
}
var wsUsers = make(map[string]*websocket.Conn)

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

func InitDb() *Database {
	connString := "host=db user=doxir dbname=doxir password=doxir sslmode=disable"
	db, err := sql.Open("postgres", connString)
	if err != nil {
		panic(err)
	}
	return &Database{db: db}
}

func Login(w http.ResponseWriter, r *http.Request) {
	login := &LoginRequest{}
	err := json.NewDecoder(r.Body).Decode(&login)
	if err != nil {
		//panic(err)
		return
	}
	response := &Response{}
	valid, _ := database.Login(login.Username, login.Password)
	if valid {
		response = &Response{Status: 200, Message: "ok"}
		w.WriteHeader(http.StatusOK)
	} else {
		response = &Response{Status: 401, Message: "unauthorized"}
		w.WriteHeader(http.StatusUnauthorized)
	}
	json.NewEncoder(w).Encode(response)
}

func NewUser(w http.ResponseWriter, r *http.Request) {
	// TODO: change name
	create := &LoginRequest{}
	err := json.NewDecoder(r.Body).Decode(&create)
	if err != nil {
		//panic(err)
		return
	}
	response := &Response{}
	err = database.CreateUser(create.Username, create.Password)
	if err != nil {
		response = &Response{Status: 403, Message: "invalid"}
	} else {
		response = &Response{Status: 200, Message: "ok"}
	}
	json.NewEncoder(w).Encode(response)
}

func Submit(w http.ResponseWriter, r *http.Request) {
	submission := &SubmitRequest{}
	err := json.NewDecoder(r.Body).Decode(&submission)
	if err != nil {
		//panic(err)
		return
	}
	body, err := json.Marshal(submission)
	channelQueue.SendCommand(body)
	response := &Response{Status: 200, Message: "ok"}
	json.NewEncoder(w).Encode(response)
}

func Coder(w http.ResponseWriter, r *http.Request) {
	c, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Printf("upgrade: %v", err)
		return
	}
	defer SocketDisconnect(c)
	for {
		_, message, err := c.ReadMessage()
		if err != nil {
			fmt.Printf("read: %v", err)
			break
		}
		var msg json.RawMessage
		envelope := &WebsocketMessage{
			Message: &msg,
		}
		if err := json.Unmarshal(message, envelope); err != nil {
			fmt.Printf("error decoding json: %v", err)
			break
		}
		switch envelope.Action {
		case "register":
			var r WebsocketRegister
			if err := json.Unmarshal(msg, &r); err != nil {
				fmt.Printf("error registering: %v", err)
				break
			}
			fmt.Printf("user registered: %v", r.Username)
			wsUsers[r.Username] = c
		default:
			break
		}
	}
}

func SocketDisconnect(s *websocket.Conn) {
	// TODO: is this scalable?  maybe pass in username or something
	for username, conn := range wsUsers {
		if conn == s {
			delete(wsUsers, username)
			break
		}
	}
}

func (queue *ChannelQueues) SendCommand(submission []byte) {
	err := queue.CommandChannel.Publish(
		"",
		"commands",
		false,
		false,
		amqp.Publishing{
			ContentType: "application/json",
			Body:        submission,
		},
	)
	if err != nil {
		//panic(err)
		return
	}
}

func (queue *ChannelQueues) ListenForLogs() {
	logs, err := queue.LogChannel.Consume("", "logs", false, false, false, false, nil)
	if err != nil {
		//panic(err)
		return
	}
	go func() {
		for log := range logs {
			response := &ContainerLog{}
			json.Unmarshal(log.Body, &response)
			fmt.Printf("user map is: %v", wsUsers)
			if _, ok := wsUsers[response.Username]; ok {
				fmt.Printf("going to write to user: %v", response.Username)
				wsUsers[response.Username].WriteMessage(websocket.TextMessage, []byte(response.Log))
			} else {
				fmt.Printf("user not found in map")
			}
		}
	}()
}

func (db *Database) Login(username string, password string) (bool, error) {
	res, err := db.db.Query("SELECT * FROM users where username = $1 and password = $2", username, password)
	if err != nil {
		return false, err
	}
	if !res.Next() {
		return false, nil
	}
	return true, nil
}

func (db *Database) CreateUser(username string, password string) error {
	_, err := db.db.Query("INSERT INTO users(username, password) VALUES ($1, $2)", username, password)
	return err
}

func main() {
	database = InitDb()
	commandChannel, logChannel := InitQueues()
	channelQueue = &ChannelQueues{
		CommandChannel: commandChannel,
		LogChannel:     logChannel,
	}
	channelQueue.ListenForLogs()
	router := mux.NewRouter()
	router.HandleFunc("/", SayHello)
	router.HandleFunc("/login", Login)
	router.HandleFunc("/user/create", NewUser)
	router.HandleFunc("/submit", Submit)
	router.HandleFunc("/coder", Coder)

	allowedHeaders := handlers.AllowedHeaders([]string{"X-Requested-With", "Content-Type"})
	allowedOrigins := handlers.AllowedOrigins([]string{"*"})
	allowedMethods := handlers.AllowedMethods([]string{"GET", "HEAD", "POST", "PUT", "DELETE", "OPTIONS"})

	if err := http.ListenAndServe(":3000", handlers.CORS(allowedHeaders, allowedOrigins, allowedMethods)(router)); err != nil {
		panic(err)
	}
	fmt.Printf("Server running at port 3000...")
}
