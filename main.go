package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Inside handler")
	bytes, err := ioutil.ReadFile("index.html")
	if err != nil {
		fmt.Fprintf(w, "error")
	} else {
		fmt.Fprintf(w, "%s", bytes)
	}
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Listening on http://localhost:80/")
	http.ListenAndServe(":80", nil)
}
