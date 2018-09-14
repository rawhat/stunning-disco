FROM node:latest

RUN mkdir -p /opt/app

COPY package.json /opt/app
COPY package-lock.json /opt/app
COPY webpack.config.js /opt/app

WORKDIR /opt/app

RUN chown -R node:node /opt/app
USER node

RUN npm i

CMD node_modules/.bin/webpack-dev-server --hot --config webpack.config.js --host 0.0.0.0
#CMD /bin/bash
