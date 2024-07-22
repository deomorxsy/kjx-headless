# libbpf
FROM debian:bookworm as libbpf_builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates gcc make pkg-config libelf-dev

COPY ./ /build/ebpf_exporter

RUN make -j $(nproc) -C /build/ebpf_exporter libbpf.a && \
    tar -C /build/ebpf_exporter/libbpf/dest -czf /build/libbpf.tar.gz .

# ebpf_exporter binary
FROM golang:1.22-bookworm as ebpf_exporter_builder

RUN apt-get update && \
    apt-get install -y libelf-dev pci.ids

COPY --from=libbpf_builder /build/ebpf_exporter/libbpf /build/ebpf_exporter/libbpf

COPY ./ /build/ebpf_exporter

RUN make -j $(nproc) -C /build/ebpf_exporter build && \
    /build/ebpf_exporter/ebpf_exporter --version


# examples
FROM debian:bookworm as examples_builder

RUN apt-get update && \
    apt-get install -y clang-16 make bash

COPY --from=libbpf_builder /build/ebpf_exporter/libbpf /build/ebpf_exporter/libbpf

COPY ./ /build/ebpf_exporter

RUN make -j $(nproc) -C /build/ebpf_exporter/examples CC=clang-16

#ENTRYPOINT["/bin/sh"]

FROM alpine:3.18 as relay

WORKDIR /app

COPY --from=examples_builder /build/ebpf_exporter/ /app
COPY --from=ebpf_exporter_builder build/ebpf_exporter/ebpf_exporter /app

ENTRYPOINT ["/bin/sh"]
