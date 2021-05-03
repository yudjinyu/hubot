# ------------------------------------------------------
#                       Dockerfile
# ------------------------------------------------------
# image:    hubot
# name:     minddocdev/hubot
# repo:     https://github.com/mind-doc/hubot
# Requires: node:alpine
# authors:  development@minddoc.com
# ------------------------------------------------------

FROM node:lts-alpine

LABEL maintainer="development@minddoc.com"

# Install hubot dependencies
RUN apk update\
 && apk upgrade\
 && apk add jq\
 && apk add curl\
 && npm install -g yo generator-hubot@next\
 && rm -rf /var/cache/apk/*

# Create hubot user with privileges
RUN addgroup -g 501 hubot\
 && adduser -D -h /hubot -u 501 -G hubot hubot
ENV HOME /home/hubot
WORKDIR $HOME
COPY entrypoint.sh ./
RUN chown -R hubot:hubot .
USER hubot

# Install hubot version HUBOT_VERSION
ENV HUBOT_NAME "robot"
ENV HUBOT_OWNER "MindDoc <development@minddoc.com>"
ENV HUBOT_DESCRIPTION "A robot may not harm humanity, or, by inaction, allow humanity to come to harm"
RUN yo hubot\
 --adapter=slack\
 --owner="$HUBOT_OWNER"\
 --name="$HUBOT_NAME"\
 --description="$HUBOT_DESCRIPTION"\
 --defaults
ARG HUBOT_VERSION="3.3.2"
RUN jq --arg HUBOT_VERSION "$HUBOT_VERSION" '.dependencies.hubot = $HUBOT_VERSION' package.json > /tmp/package.json\
 && mv /tmp/package.json .

# check argo
RUN curl -sLO https://github.com/argoproj/argo/releases/download/v3.0.2/argo-linux-amd64.gz
RUN gunzip argo-linux-amd64.gz 
RUN chmod +x argo-linux-amd64
RUN mv ./argo-linux-amd64 /usr/local/bin/argo

#EXPOSE 80

ENTRYPOINT ["./entrypoint.sh"]

CMD ["--name", "$HUBOT_NAME", "--adapter", "slack"]
