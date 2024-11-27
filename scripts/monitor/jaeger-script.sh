#!/bin/sh
image1=8690f8975ba4

podman run --rm -it --name jaeger \
    -e COLLECTOR_ZIPKIN_HOST_PORT=:9411 \
    -p 5775:5775 \
    -p 6831:6831 \
    -p 6832:6832 \
    -p 5778:5778     \
    -p 16686:16686   \
    -p 14268:14268   \
    -p 14250:14250   \
    -p 9411:9411     \
    $image1

