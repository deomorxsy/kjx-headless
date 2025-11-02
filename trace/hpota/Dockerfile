FROM elixir:1.19.1-otp-28-alpine as build

ARG MIX_ENV="prod"
ARG MIX_ENV
ENV MIX_ENV="${MIX_ENV}"
ENV HPOTA_USER="hpota"
# COPY ./trace/hpota/mix.exs ./trace/hpota/mix.lock ./
# COPY ./config/config.exs ./config/$MIX_ENV.exs config/
# COPY config/runtime.exs config/

WORKDIR /app
COPY ./trace/hpota/ .

RUN <<EOF
    apk upgrade && apk update && \
        apk add git make clang linux-headers

(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

# to include bpf/bpf_helpers.h
apk add libbpf-dev

HPOTA_USER="hpota"

# create user and group
addgroup -g 1000 -S "${HPOTA_USER}" && \
adduser -s /bin/sh -u 1000 -G "${HPOTA_USER}" \
    -h "/home/${HPOTA_USER}" -D "${HPOTA_USER}" && \

# copy directory to user home
cp -r /app/ /home/hpota/

# certify it will have the correct user:group permissions
chown -R ${HPOTA_USER}:${HPOTA_USER} /home/${HPOTA_USER}

EOF


# Get dependencies and compile project
WORKDIR /home/hpota/app/
RUN <<EOF
cd /home/hpota/app/

su "${HPOTA_USER}" -c "
    mix deps.get >> /home/hpota/foo && \
    printf '\n================================\n' && \
    MIX_ENV=test elixir -S mix test >> /home/hpota/foo && \
    printf '\n================================\n' && \

    mix deps.compile >> /home/hpota/foo && \
    printf '\n================================\n' && \
    mix release >> /home/hpota/foo && \
    printf '\n\nEND'
"

ls -allhtr

EOF



# RUN <<EOF
#

### # Get dependencies
### RUN mix deps.get
### # Run tests
### RUN MIX_ENV=test elixir -S mix test
### RUN mkdir -p ./config
### RUN mix deps.compile
### RUN mix release

# =============
# artifact
# =============
FROM alpine:3.22 as relay

# COPY --from=build --chown="${USER}":"${USER}" /app/_build/"${MIX_ENV}"/rel/api_release_demo ./
COPY --from=build /home/hpota/foo /foo.txt
RUN cat /foo.txt

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["cat", "/foo.txt"]
