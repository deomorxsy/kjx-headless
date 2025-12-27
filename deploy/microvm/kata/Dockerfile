FROM alpine:3.22 AS builder
# FROM rust:1.90.0-alpine3.20 AS builder

COPY ./scripts/sandbox/kata-startup.sh /app/scripts/sandbox/kata-startup.sh
COPY ./scripts/packages/demo-replased.sh /app/scripts/packages/demo-replased.sh

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /app/

RUN <<EOF

apk upgrade && apk update && \
    apk add git

ls -allhtr

#MODE="build" . ./scripts/sandbox/kata-startup.sh
EOF

RUN <<EOF

if ! (MODE="kata-tarball" . /app/scripts/sandbox/kata-startup.sh); then
    printf "\n|> Error: could not execute the [kata-tarball] function from the kata-startup.sh shellscript. Exiting now...\n\n"
    return 1
fi
printf "\n|> Succesfully run [kata-tarball] from kata-startup.sh. Proceeding..."

if ! (ls -allhtr "/kata-tarball-pkg.tar.gz"); then
    echo "|> kata-tarball NOT FOUND. EXITING..."
    return 1
fi
echo "|> FOUND THE SO TARBALL \O/ ...[PASSED]"

EOF


FROM alpine:3.22 AS relay

WORKDIR /app
COPY --from=builder /root/artifacts/sources/kata-core.tar.gz .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
