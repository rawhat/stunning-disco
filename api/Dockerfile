FROM rustlang/rust:nightly

RUN apt update && apt install -y entr

WORKDIR /home/alex

COPY . .

EXPOSE 8000

#CMD ls main.rs | entr cargo run
CMD cargo run
