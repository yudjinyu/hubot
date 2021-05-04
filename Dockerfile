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

RUN mkdir /home/hubot
ENV HOME /home/hubot

# Install hubot dependencies
RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/v$KUBE_VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && curl -L https://github.com/argoproj/argo/releases/download/v3.0.2/argo-linux-amd64.gz -o $HOME/argo-linux-amd64.gz\
 && gunzip $HOME/argo-linux-amd64.gz \
 && apk add jq\
 && npm install -g yo generator-hubot\
 && npm install hubot-scripts \
 && npm install hubot-slack --save \
 && apk del --purge deps \
 && rm -rf /var/cache/apk/*

# Create hubot user with privileges
RUN addgroup -g 501 hubot\
 && adduser -D -h /hubot -u 501 -G hubot hubot
WORKDIR $HOME
COPY entrypoint.sh ./

RUN chown -R hubot:hubot . 
RUN chown -R hubot:hubot /usr/local/bin/kubectl 

RUN mv ./argo-linux-amd64 /usr/local/bin/argo
USER hubot

# Install hubot version HUBOT_VERSION
ENV HUBOT_NAME "rbot"
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

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]

CMD ["--name", "$HUBOT_NAME", "--adapter", "slack"]
