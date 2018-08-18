FROM node:latest

WORKDIR /opt/app

COPY package.json .
COPY package-lock.json .

RUN npm i

CMD node_modules/.bin/webpack-dev-server --hot --config webpack.config.js