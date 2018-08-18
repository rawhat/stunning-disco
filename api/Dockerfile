FROM golang:latest

WORKDIR /opt/app

COPY . .

RUN go build -o main .

CMD ["./main"]