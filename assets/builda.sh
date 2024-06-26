#!/bin/sh
#


GO_LDFLAGS_VARS := -X $BUILD_VAR_PREFIX.Version=$(BUILD_VERSION) \
	-X $(BUILD_VAR_PREFIX).Branch=$(BUILD_BRANCH) \
	-X $(BUILD_VAR_PREFIX).Revision=$(BUILD_REVISION) \
	-X $(BUILD_VAR_PREFIX).BuildUser=$(BUILD_USER) \
	-X $(BUILD_VAR_PREFIX).BuildDate=$(BUILD_DATE)

CGO_LDFLAGS="-l bpf" GO_BUILD_ARGS="-tags netgo,osusergo" GO_LDFLAGS='-extldflags "-static"' go build -o ebpf_exporter -v ./cmd/ebpf_exporter

