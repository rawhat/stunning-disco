package main

import (
	"encoding/json"
	"fmt"
	//"io/ioutil"
	"net/http"

	"github.com/gorilla/mux"
)

func SayHello(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)
	w.Write([]byte("Hello world!"))
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type LoginResponse struct {
	Status  int    `json:"status"`
	Message string `json:"message"`
}

func Login(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)
	login := &LoginRequest{}
	err := json.NewDecoder(r.Body).Decode(&login)
	if err != nil {
		panic(err)
	}
	response := &LoginResponse{}
	if login.Username == "username" && login.Password == "password" {
		response = &LoginResponse{Status: 200, Message: "ok"}
		w.WriteHeader(http.StatusOK)
	} else {
		response = &LoginResponse{Status: 401, Message: "unauthorized"}
		w.WriteHeader(http.StatusUnauthorized)
	}
	json.NewEncoder(w).Encode(response)
}

func enableCors(w *http.ResponseWriter) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
	(*w).Header().Set("Access-Control-Allow-Headers", "*")
	(*w).Header().Set("Access-Control-Allow-Methods", "*")
}

func main() {
	router := mux.NewRouter()
	router.HandleFunc("/", SayHello).Methods("GET")
	router.HandleFunc("/login", Login).Methods("POST", "OPTIONS")
	if err := http.ListenAndServe(":3000", router); err != nil {
		panic(err)
	}
	fmt.Printf("Server running at port 3000...")
}
