FROM alpine:3.22 AS builder
# FROM rust:1.90.0-alpine3.20 AS builder

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /app/
COPY ./scripts/sandbox/kata-startup.sh /app/scripts/

RUN <<EOF

apk upgrade && apk update && \
    apk add git

ls -allhtr

MODE="build" . ./scripts/kata-startup.sh
EOF

FROM alpine:3.22 AS empty

COPY --from=builder /root/artifacts/sources/kata-core.tar.gz .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
