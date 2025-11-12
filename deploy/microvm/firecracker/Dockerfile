FROM alpine:3.22 as builder

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /app/
COPY ./scripts/sandbox/firecracker-startup.sh /app/scripts/

RUN MODE="build" . ./scripts/firecracker.sh

FROM alpine:3.22 as empty

COPY --from=builder /root/artifacts/sources/firecracker-core.tar.gz .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
