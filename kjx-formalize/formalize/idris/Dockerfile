FROM alpine:3.20 AS builder

# The global pack.toml file goes to:
ENV PACK_USER_DIR="$XDG_CONFIG_HOME/pack/pack.toml"

# The built compiler as well as installed libraries and applications go to:
ENV PACK_STATE_DIR="$XDG_STATE_HOME/pack/"

# Cached .ipkg files and git repositories go to:
ENV PACK_CACHE_DIR="$XDG_CACHE_HOME/pack/"

RUN <<EOF
# apk upgrade && apk update && \
#     apk add git racket linux-headers \
#     llvm clang gmp-dev \
#     bash curl make

(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

apk upgrade && apk update && \
    apk add idris2 racket

# # --auto
# raco pkg new hmmm...
# raco pkg install --deps search-auto compiler-lib
# raco pkg install --deps search-auto r6rs-lib
# raco pkg install --deps search-auto math
#
# IDRIS2_VERSION=Idris2-0.8.0
#
# mkdir -p /idris2-install
#
# rm -rf /root/.cache/pack/clones/Idris2
# rm -rf /root/.local/state/pack
# rm -rf /root/.cache/pack/clones/idris2-pack-db
#
# cd /idris2-install && git clone https://github.com/stefan-hoeck/idris2-pack.git pack
#
# bash ./pack/install.bash


EOF



# run tests
WORKDIR /app
COPY . .
RUN ls -allhtr
RUN <<EOF
idris_tests() {
for dir in /app/*; do

if [ -d $dir ]; then
cd "$dir" && idris2 --profile --build package.ipkg >> /app/test_result_"$(basename "$dir")"_.txt 2>&1 &&  \
cat "/app/test_result_*.txt" && \
cd - || return

elif [ -f $dir ]; then
echo "A file $dir was found. Skipping..."

fi
done
}
idris_tests
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
