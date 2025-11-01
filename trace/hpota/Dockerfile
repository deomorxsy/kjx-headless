FROM elixir:1.19.1-otp-28-alpine

ARG MIX_ENV="prod"

WORKDIR /app

RUN mix local.hex --force && local.rebar --force

ARG MIX_ENV
ENV MIX_ENV="${MIX_ENV}"

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

RUN mkdir config
COPY config/config.exs config/$MIX_ENV.exs config/

RUN mix deps.compile

COPY config/runtime.exs config/
RUN mix release

# =============
# artifact
# =============
FROM alpine:3.20 as relay

ARG MIX_ENV

RUN apk add --no-cache libstdc++ openssl ncurses-libs

ENV USER="elixir"
WORKDIR "/home/${USER}/app"

RUN addgroup -g 1000 -S "${USER}" && adduser -s /bin/sh -u 1000 -G "${USER}" -h "/home/${USER}" -D "${USER}" && su "${USER}"

USER "${USER}"

COPY --from=build --chown="${USER}":"${USER}" /app/_build/"${MIX_ENV}"/rel/api_release_demo ./

ENTRYPOINT ["bin/api_release_demo"]

CMD ["start"]
