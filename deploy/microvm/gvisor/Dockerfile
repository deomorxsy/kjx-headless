FROM alpine:3.22 AS builder

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /app/
COPY ./scripts/sandbox/gvisor-startup.sh /app/scripts/

RUN MODE="build" . ./scripts/gvisor-startup.sh

FROM alpine:3.22 AS empty

COPY --from=builder /root/artifacts/sources/gvisor-core.tar.gz .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
