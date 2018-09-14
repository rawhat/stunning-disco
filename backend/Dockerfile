FROM elixir:latest

COPY . /opt/app

WORKDIR /opt/app/doxir

RUN useradd docker
RUN mkdir -p /home/docker
RUN chown -R docker:docker /opt/app
RUN chown -R docker:docker /home/docker
USER docker

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix deps.get
RUN mix deps.compile

CMD ["mix", "run", "lib/doxir/application.ex"]
