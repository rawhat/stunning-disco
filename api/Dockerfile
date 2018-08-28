FROM golang:latest

WORKDIR /opt/app

RUN go get -u github.com/gorilla/mux
RUN curl http://entrproject.org/code/entr-4.1.tar.gz -o entr.tar.gz
RUN tar xvfz entr.tar.gz
RUN cd eradman-entr-f4e2cbe57708 && ./configure && make install
RUN cd /opt/app

COPY buildrun.sh .
COPY auto.sh .

CMD /opt/app/auto.sh
