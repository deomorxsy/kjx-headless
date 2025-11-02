FROM busybox:1.37.0-musl as builder
# just to get the statically compiled files

FROM alpine:3.20 as base

COPY --from=builder /* /

# RUN apt-get update && apt-get install --yes runit
RUN <<EOF
apk upgrade && apk update && \
    apk add runit

EOF

RUN <<EOF
mkdir -p /etc/service/my_service

(
cat <<EOL
#!/bin/sh

exec /my_service/my_service

EOL
) | tee /etc/service/my_service/run && \
    chmod +x /etc/service/my_service/run

mkdir -vp /etc/init.d/ && \
ln -s /usr/bin/sv /etc/init.d/my_service

EOF

WORKDIR /app

COPY app .

CMD ["runsvdir", "/etc/service"]
