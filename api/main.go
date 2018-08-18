package main

import (
	"log"
	"net/http"
)

func sayHello(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)
	w.Write([]byte("Hello, world!"))
}

func enableCors(w *http.ResponseWriter) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
}

func main() {
	http.HandleFunc("/", sayHello)
	if err := http.ListenAndServe(":3000", nil); err != nil {
		panic(err)
	}
	log.Printf("Server running at port 3000...")
}
