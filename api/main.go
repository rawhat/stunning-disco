package main

import (
  "database/sql"
	"encoding/json"
	"fmt"
	"net/http"

  "github.com/gorilla/handlers"
	"github.com/gorilla/mux"
  "github.com/streadway/amqp"
  _ "github.com/lib/pq"
)

type ChannelQueue struct {
  channel *amqp.Channel
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

type SubmitRequest struct {
  Language string `json:"language"`
  Script   string `json:"script"`
  Username string `json:"username"`
}

func InitQueue() *amqp.Channel {
  conn, err := amqp.Dial("amqp://queue/")
  if err != nil {
    panic(err)
  }
  //defer conn.Close()
  ch, err := conn.Channel()
  if err != nil {
    panic(err)
  }
  //defer ch.Close()
  _, err = ch.QueueDeclare(
    "test",
    false,
    false,
    false,
    false,
    nil,
  )
  if err != nil {
    panic(err)
  }
  return ch
}

func InitDb() *Database {
  connString := "host=db user=postgres dbname=postgres sslmode=disable"
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
		panic(err)
	}
	response := &Response{}
	if login.Username == "username" && login.Password == "password" {
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
    panic(err)
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
    panic(err)
  }
  body, err := json.Marshal(submission)
  if err != nil {
    panic(err)
  }
  queue := InitQueue()
  err = queue.Publish(
    "",
    "test",
    false,
    false,
    amqp.Publishing {
      ContentType: "application/json",
      Body:        body,
  })
  if err != nil {
    panic(err)
  }
  response := &Response{Status: 200, Message: "ok"}
  json.NewEncoder(w).Encode(response)
}

func (db *Database) CreateUser(username string, password string) error {
  _, err := db.db.Query("INSERT INTO users(username, password) VALUES ($1, $2)", username, password)
  return err
}

var database *Database

func main() {
  database = InitDb()
	router := mux.NewRouter()
	router.HandleFunc("/", SayHello)
	router.HandleFunc("/login", Login)
  router.HandleFunc("/user/create", NewUser)
  router.HandleFunc("/submit", Submit)

  allowedHeaders := handlers.AllowedHeaders([]string{"X-Requested-With", "Content-Type"})
  allowedOrigins := handlers.AllowedOrigins([]string{"*"})
  allowedMethods := handlers.AllowedMethods([]string{"GET", "HEAD", "POST", "PUT", "DELETE", "OPTIONS"})

	if err := http.ListenAndServe(":3000", handlers.CORS(allowedHeaders, allowedOrigins, allowedMethods)(router)); err != nil {
		panic(err)
	}
	fmt.Printf("Server running at port 3000...")
}
