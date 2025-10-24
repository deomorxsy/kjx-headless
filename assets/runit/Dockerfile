FROM busybox:1.36.1-musl as builder
# just to get the statically compiled files

# FROM ubuntu
FROM alpine:3.18 as base

# RUN apt-get update && apt-get install --yes runit
RUN <<EOF
apk upgrade && apk update && \
    apk add runit

EOF

RUN <<EOF
mkdir /etc/service/my_service \
    && /bin/sh -c "echo -e '"'#!/bin/sh\nexec /my_service/my_service\n'"' > /etc/service/my_service/run" \
    && chmod +x /etc/service/my_service/run

#RUN

mkdir -vp /etc/init.d/ && ln -s /usr/bin/sv /etc/init.d/my_service

EOF

WORKDIR /app

COPY app .

CMD ["runsvdir", "/etc/service"]
