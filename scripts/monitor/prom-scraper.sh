#!/bin/sh

# get local dynamic ip
DYNIP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $7}')

cat  > ./deploy/monitoring/prom-metrics_ebpfexp.yaml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'ebpf_exporter'
    static_configs:
      - targets: ['$DYNIP:9435']

  - job_name: 'prometheus'
    scrape_interval: 1m
    static_configs:
      - targets: ['localhost:9100']

remote_write:
  - url: '<Your Prometheus remote_write endpoint>'
    basic_auth:
      username: '<Your Grafana Username>'
      password: '<Your Grafana Cloud Access Policy Token>'


EOF

# prom/prometheus:latest
podman run \
    --rm -it \
    --name prometheus \
    -p 9090:9090 \
    --net=host \
    -v ./deploy/monitoring/prom-metrics_ebpfexp.yaml:/etc/prometheus/prometheus.yml \
    0a1bcc4b2d6a
