package main

import (
	"log"
	"net/http"
)

func sayHello(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Hello, world!"))
}

func main() {
	http.HandleFunc("/", sayHello)
	if err := http.ListenAndServe(":3000", nil); err != nil {
		panic(err)
	}
	log.Printf("Server running at port 3000...")
}