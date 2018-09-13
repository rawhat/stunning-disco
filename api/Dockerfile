FROM crystallang/crystal:latest

RUN apt update && apt install -y curl

RUN curl -fsSLo- https://raw.githubusercontent.com/samueleaton/sentry/master/install.cr | crystal eval

RUN useradd docker
RUN chown -R docker /opt/app
RUN mkdir -p /home/docker
RUN chown -R docker /home/docker
USER docker

WORKDIR /opt/app

CMD /bin/bash
