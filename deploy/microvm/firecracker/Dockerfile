FROM alpine:3.22 AS builder
# FROM rust:1.90.0-alpine3.20 as builder

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /app/
COPY ./scripts/sandbox/firecracker-startup.sh /app/scripts/

RUN <<EOF

apk upgrade && apk update && \
    apk add git

ls -allhtr

MODE="build" . ./scripts/firecracker-startup.sh

EOF

#FROM alpine:3.22 AS empty

#COPY --from=builder /root/artifacts/sources/firecracker-core.tar.gz .

#RUN echo "done!!!"

#ENTRYPOINT ["/bin/sh"]
