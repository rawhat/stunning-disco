FROM elixir:latest

COPY . /opt/app

WORKDIR /opt/app/doxir

RUN groupadd docker
RUN useradd -r -u 1000 -g docker docker
RUN mkdir -p /home/docker
RUN chown -R docker:docker /opt/app
RUN chown -R docker:docker /home/docker
USER docker

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix deps.get
RUN mix deps.compile

CMD ["mix", "phx.server"]
