package main

import (
	"log"
	"net/http"
	"html/template"
   "regexp"
   "bytes"

	"github.com/gorilla/websocket"
)

var clients = make(map[*websocket.Conn]bool)
var broadcast = make(chan Message)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type Message struct {
	Email    string `json:"email"`
	Username string `json:"username"`
	Message  string `json:"message"`
}

func main() {
   //Route to the HTML
	http.HandleFunc("/test.html", filehandler)
   //Route to the websockets server
   http.HandleFunc("/websocketsserver", handleConnections)

	go handleMessages()

	log.Println("new HTTPS server started on :8081")
	err := http.ListenAndServeTLS(":8081", "fullchain.pem", "privkey.pem", nil)
	if err != nil {
		log.Fatal("ListenAndServeTLS: ", err)
	}
}

func filehandler(w http.ResponseWriter, req *http.Request) {
    http.ServeFile(w, req, "chat.html")
}

func handleConnections(w http.ResponseWriter, r *http.Request) {
	// Upgrade initial GET request to a websocket
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	defer ws.Close()

	// Register our new client
	clients[ws] = true

	for {
		var msg Message
		// Read in a new message as JSON and map it to a Message object
		err := ws.ReadJSON(&msg)
		if err != nil {
			delete(clients, ws)
			break
		}
		// Send the newly received message to the broadcast channel
		broadcast <- msg
	}
}

func handleMessages() {
   t, _ := template.New("foo").Parse(`{{define "T"}}{{.}}{{end}}`)
   var buf bytes.Buffer
   var errorflag bool
   r := regexp.MustCompile(`^(([[:print:]])|([\p{L}]))+$`)
	for {
		// Grab the next message from the broadcast channel
	   msg := <-broadcast
      errorflag = false
      buf.Reset()
      err := t.ExecuteTemplate(&buf, "T", msg.Email)
      if ((err != nil) || (!r.MatchString(msg.Email))){
         errorflag = true
      }else{
         msg.Email = buf.String()
      }
      buf.Reset()
      err = t.ExecuteTemplate(&buf, "T", msg.Username)
      if ((err != nil) || (!r.MatchString(msg.Username))){
         errorflag = true
      }else{
         msg.Username = buf.String()
      }
      buf.Reset()
      err = t.ExecuteTemplate(&buf, "T", msg.Message)
      if ((err != nil) || (!r.MatchString(msg.Message))){
         errorflag = true
      }else{
         msg.Message = buf.String()
      }
      if (errorflag){
         log.Println("Error -> ", msg)
         continue
      }
      log.Println(msg)
		// Send it out to every client that is currently connected
		for client := range clients {
			err := client.WriteJSON(msg)
			if err != nil {
				client.Close()
				delete(clients, client)
			}
		}
	}
}
