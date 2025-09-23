FROM alpine:3.20 AS builder

RUN <<EOF
apk upgrade && apk update && \
    apk add dune ocaml musl-dev
EOF


# run tests
WORKDIR /app
COPY . .
RUN ls -allhtr
RUN <<EOF
ocaml_tests() {
for dir in /app/*; do
    if [ -d $dir ]; then
    cd "$dir" && dune runtest && dune clean && \
    cat ./stack.yaml && \
    stack build --test >> /app/test_result_"$(basename "$dir")"_.txt 2>&1
    cd - || return
    elif [ -f $dir ]; then
        echo "A file $dir was found. Skipping..."
    fi
done
}
ocaml_tests
EOF


# ======================
# 2. Relay Step
# ======================
FROM alpine:3.20 as relay

WORKDIR /tests

COPY --from=builder /app/test_result_*_.txt .

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
#CMD ["apk upgrade && apk update && apk add dune ocaml musl-dev"]
CMD ["cat /tests/test_result_*_.txt"]
