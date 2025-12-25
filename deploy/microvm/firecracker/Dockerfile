# FROM alpine:3.22 AS builder
# FROM rust:1.90.0-alpine3.20 as builder
FROM golang:1.24-alpine3.22 AS builder

ENV PATH="/usr/lib/go-1.23/bin:$PATH"
ENV PATH="/usr/lib/go-1.24/bin:${PATH}"

ARG PATH="/usr/lib/go-1.23/bin:$PATH"
ARG PATH="/usr/lib/go-1.24/bin:${PATH}"

# user management
ENV SANDBOX_USER="firecontainerd"
ARG SANDBOX_USER="firecontainerd"

# firecracker artifact directory
ENV FIREART="/home/${SANDBOX_USER}/fireart"
ARG FIREART="/home/${SANDBOX_USER}/fireart"

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /app/
COPY ./scripts/sandbox/firecracker-startup.sh /app/scripts/

RUN <<EOF

# Set dependencies, last two for debugging
apk upgrade && apk update && \
    apk add git make curl \
        vim fzf


# Set dependencies from [edge] branch
(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

apk add e2fsprogs bc util-linux gnupg device-mapper

EOF

WORKDIR /app
RUN <<EOF

# user management
SANDBOX_USER="firecontainerd"
# firecracker artifact directory
FIREART="/home/${SANDBOX_USER}/fireart"


PATH="/usr/lib/go-1.24/bin:${PATH}"
export PATH

SANDBOX_USER=firecontainerd

# Create user and group
addgroup -g 1000 -S "${SANDBOX_USER}" && \
adduser -s /bin/sh -u 1000 -G "${SANDBOX_USER}" \
    -h "/home/${SANDBOX_USER}" -D "${SANDBOX_USER}" && \

# Certify it will have the correct user:group permissions
chown -R ${SANDBOX_USER}:${SANDBOX_USER} /home/${SANDBOX_USER}

mkdir -p "/home/${SANDBOX_USER}/app"
mkdir -p "${FIREART}/json-config/"

EOF


# su "${SANDBOX_USER}" -c "
#
# MODE="build" . ./scripts/firecracker-startup.sh
# "
#
# ls -allhtr
WORKDIR "/home/${SANDBOX_USER}/app"

RUN <<EOF

# user management
SANDBOX_USER="firecontainerd"
# firecracker artifact directory
FIREART="/home/${SANDBOX_USER}/fireart"


mkdir -p "${FIREART}/json-config/"

if ! (git clone https://github.com/firecracker-microvm/firecracker-containerd.git); then
    echo "|> Error: could not clone the firecracker-containerd repository. Exiting now..."
    return 1
    fi
    echo "|> Sucessfully cloned the firecracker-containerd repository. Proceeding..."

cd ./firecracker-containerd/ || return

if ! (make all); then
    echo "|> Error: failed running [make all]. Exiting now..."
    return 1
    fi
    echo "|> Sucessfully runned [make all]. Proceeding..."

# ls -l ./firecracker-control/cmd/containerd/
# ls -l ./bin


if ! (cp -r ./bin/ /home/firecontainerd/fireart/); then
    echo "|> Error: could not copy the [./bin] directory to [/home/firecontainerd/fireart/]. Exiting now..."
    return 1
    fi
    echo "|> Sucessfully copied the [./bin] directory to [/home/firecontainerd/fireart/]. Proceeding..."

ls -l /home/firecontainerd/fireart/

# check if both binary filepaths exist
if [ -f ./firecracker-control/cmd/containerd/firecracker-ctr ] && [ -f ./firecracker-control/cmd/containerd/firecracker-containerd ]; then

 if ! (cp ./firecracker-control/cmd/containerd/firecracker-ctr /home/firecontainerd/fireart/); then
    echo "|> Error: could not copy the [./firecracker-control/cmd/containerd/firecracker-ctr] binary directory to [/home/firecontainerd/fireart/]. Exiting now..."
    return 1
    fi
    echo "|> Sucessfully copied the [./firecracker-control/cmd/containerd/firecracker-ctr] binary directory to [/home/firecontainerd/fireart/]. Proceeding..."

    if ! (cp ./firecracker-control/cmd/containerd/firecracker-containerd /home/firecontainerd/fireart/); then
    echo "|> Error: could not copy the [./firecracker-control/cmd/containerd/firecracker-containerd] binary directory to [/home/firecontainerd/fireart/]. Exiting now..."

        return 1
    fi
    echo "|> Sucessfully copiedthe [./firecracker-control/cmd/containerd/firecracker-containerd] binary directory to [/home/firecontainerd/fireart/]. Proceeding..."
fi

# just to make...sure...
if ! (make); then
    echo "|> Error: failed running [make all]. Exiting now..."
    return 1
    fi
    echo "|> Sucessfully runned [make all]. Proceeding..."
#fzf -e
ls -allhtr runtime/
if !( cp ./runtime/containerd-shim-aws-firecracker /home/firecontainerd/fireart/); then
echo "|> Error: could not copy the [./runtime/containerd-shim-aws-firecracker] binary directory to [/home/firecontainerd/fireart/]. Exiting now..."
return 1
fi
echo "|> Sucessfully copied the [./runtime/containerd-shim-aws-firecracker] binary directory to [/home/firecontainerd/fireart/]. Proceeding..."

# Copy JSON configuration files
FIND_JSON=$(find ./ \( -iname '*.json' \) -type f -exec ls -lt {} + | awk '{print $9}')
if ! (cp "$FIND_JSON" "${FIREART}/json-config/"); then
    echo "|> Error: could not find a [./*.json] file and copy it to [FIREART=${FIREART}]. Exiting now..."
    #return 1
fi
    echo "|> Sucessfully found at least one [./*.json] file. Proceeding..."


# if ! (cp ./examples/etc/containerd/firecracker-runtime.json); then
# echo "|> Error: could not copy the [./examples/etc/containerd/firecracker-runtime.json] binary directory to [/home/firecontainerd/fireart/]. Exiting now..."
# return 1
# fi
# echo "|> Sucessfully copied the [./examples/etc/containerd/firecracker-runtime.json] binary directory to [/home/firecontainerd/fireart/]. Proceeding..."


# create a tarball of firecracker-containerd artifacts
# warning: it relies on a networking setup with iptables
# refer to: ./scripts/packaging/iptables-setup.sh
#


if ! (tar -czf "/home/${SANDBOX_USER}/firecracker-core.tar.gz" "${FIREART}"); then
    echo "|> Error: could not create a tarball from [FIREART=${FIREART}] at [/home/${SANDBOX_USER}/firecracker-core.tar.gz]. Exiting now..."
    return 1
    fi
    echo "|> Sucessfully created a tarball from [FIREART=${FIREART}] at [/home/${SANDBOX_USER}/firecracker-core.tar.gz]. Proceeding..."

EOF

FROM alpine:3.22 AS empty

# user management
ENV SANDBOX_USER="firecontainerd"
ARG SANDBOX_USER="firecontainerd"

# firecracker artifact directory
ENV FIREART="/home/${SANDBOX_USER}/fireart"
ARG FIREART="/home/${SANDBOX_USER}/fireart"

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}


COPY --from=builder "/home/${SANDBOX_USER}/firecracker-core.tar.gz" .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
