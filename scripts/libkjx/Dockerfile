# ==================
# 1. Builder Step
# ==================
FROM alpine:3.20 as builder

COPY ./scripts/ /app/
COPY ./assets/ /app/
COPY ./artifacts/ /app/

WORKDIR /app

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["apk upgrade && apk update &&
      apk add git musl-gcc openssl-dev \
      libcrypto zlib elfutils-dev && \
      . /libkjx/static_beetor.sh"]
#CMD ["printf \"===== UNIT TEST =====\\n\\n\" && cat /tests/test_result.txt && printf \"\\n\\n===== UNIT COVERAGE =======\\n\\n\" && cat /tests/coverage_go.out && printf \"\\n\\n===== FUZZA =======\\n\\n\" && printf \"no-file-yet\""]
