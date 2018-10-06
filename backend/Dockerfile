FROM golang:latest

RUN apt update && apt install -y entr

WORKDIR /opt/app

RUN go get -u github.com/streadway/amqp
RUN go get -u github.com/docker/docker/client
RUN go get -u github.com/docker/docker/api/types
RUN go get -u github.com/docker/docker/api/types/container
RUN go get -u golang.org/x/net/context

RUN useradd docker
RUN chown -R docker /opt/app
RUN mkdir -p /home/docker
RUN chown -R docker /home/docker
USER docker

COPY buildrun.sh .
COPY auto.sh .

CMD /opt/app/auto.sh
