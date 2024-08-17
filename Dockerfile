FROM alpine:3.18 as relay

WORKDIR /app

RUN apk upgrade && apk update && \


