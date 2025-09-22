FROM denoland/deno:2.0.2

EXPOSE 8000

WORKDIR /app

USER deno
COPY ./trace/wasm/ .

# compile main app to avoid compilation at each startup/entry
RUN deno cache /app/main.ts

# warmup caches
RUN timeout 10s deno -A /app/main.ts || [$? -eq 124 ] || exit 1


CMD ["run", "--allow-net", "/app/main.ts"]
