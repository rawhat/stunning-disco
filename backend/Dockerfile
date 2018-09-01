FROM elixir:latest

COPY . /opt/app

WORKDIR /opt/app/doxir

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix deps.get
RUN mix deps.compile

CMD ["mix", "run", "lib/doxir.ex"]
