FROM golang:latest

RUN apt update && apt install -y entr

WORKDIR /opt/app

RUN go get -u github.com/gorilla/handlers
RUN go get -u github.com/gorilla/mux
RUN go get -u github.com/gorilla/websocket
RUN go get -u github.com/streadway/amqp
RUN go get -u github.com/lib/pq

RUN useradd docker
RUN chown -R docker /opt/app
RUN mkdir -p /home/docker
RUN chown -R docker /home/docker
USER docker

COPY buildrun.sh .
COPY auto.sh .

CMD /opt/app/auto.sh
