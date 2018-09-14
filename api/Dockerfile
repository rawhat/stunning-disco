FROM crystallang/crystal:latest

RUN apt update && apt install -y curl

RUN curl -fsSLo- https://raw.githubusercontent.com/samueleaton/sentry/master/install.cr | crystal eval

WORKDIR /opt/app

RUN useradd docker
RUN chown -R docker /opt/app
RUN chown docker /sentry
USER docker

COPY shard.yml .

RUN ln -s /sentry /opt/app/sentry

CMD ./sentry --install
