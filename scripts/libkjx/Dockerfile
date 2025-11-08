# ==================
# 1. Builder Step
# ==================
FROM alpine:3.20 as builder

COPY ./scripts/ /app/
COPY ./assets/ /app/
COPY ./artifacts/ /app/

WORKDIR /app

RUN <<EOF
apk upgrade && apk update && \
    apk add git musl-gcc openssl-dev \
      libcrypto zlib elfutils-dev

LIBKJX_USER=beetor

# create user and group
addgroup -g 1000 -S "${LIBKJX_USER}" && \
adduser -s /bin/sh -u 1000 -G "${LIBKJX_USER}" \
    -h "/home/${LIBKJX_USER}" -D "${LIBKJX_USER}" && \


cp -r /app/* /home/${LIBKJX_USER} && \
# certify it will have the correct user:group permissions
chown -R ${LIBKJX_USER}:${LIBKJX_USER} /home/${LIBKJX_USER}  && \

su "${LIBKJX_USER}" -c "

cd ~/app/

"
EOF

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["apk upgrade && apk update &&
      apk add git musl-gcc openssl-dev \
      libcrypto zlib elfutils-dev && \
      . /libkjx/static_beetor.sh"]
#CMD ["printf \"===== UNIT TEST =====\\n\\n\" && cat /tests/test_result.txt && printf \"\\n\\n===== UNIT COVERAGE =======\\n\\n\" && cat /tests/coverage_go.out && printf \"\\n\\n===== FUZZA =======\\n\\n\" && printf \"no-file-yet\""]
