#!/bin/sh

# fa-gha
# Fetch Artifacts from Github Actions

replacer() {

THIS_FILE_PATH="./scripts/ci-cd/fetch-artifacts.sh"

    MODE="-rep" FILE_PATH="${THIS_FILE_PATH}" . ./scripts/secrets/rep-manager.sh
}

set_vars() {

if [ "${GITHUB_ACTIONS}" = "true" ]; then

PAT_KJX_ARTIFACT="\${{ secrets.FETCH_ARTIFACT }}"

 #set_vars
# Path to place artifacts
CICD_ART_PATH="./artifacts/ci-cd"
mkdir -p "${CICD_ART_PATH}"
ARTIFACT_LIST_JSON="${CICD_ART_PATH}/artifact-list.json"
ARTIFACT_API_URI="https://api.github.com/repos/deomorxsy/kjx-headless/actions/artifacts"

# tarballs or files
ARTIFACT_LIST_JSON="${CICD_ART_PATH}/artifact-list.json"
FA_KERNEL_TARBALL=""
FA_INITRAMFS_TARBALL="./artifacts/new-initramfs.cpio.gz"
FA_SSH_ROOTFS_TARBALL=""
FA_QONQ_QDB_TARBALL=""
FA_BEETOR_TARBALL=""
FA_RUNIT_TARBALL=""
FA_ISO_TARBALL=""

# Save a list of newest artifacts
curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${PAT_KJX_ARTIFACT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
     "${ARTIFACT_API_URI}" > "${ARTIFACT_LIST_JSON}"

else
    printf "\n|> Error: this is NOT a workflow runner from Github Actions. This script leverages Actions' secrets management. Exiting now...\n\n"
fi

}

fetch_initramfs() {

set -e

set_vars

# Set initramfs URI
INITRAMFS_URL=$(
    cat "${ARTIFACT_LIST_JSON}"   | \
    jq -r '.artifacts                       | \
        map(select(.name == "initramfs"))   | \
        sort_by(.created_at)                | \
        last                                | \
        .archive_download_url'
    )


# Fetch initramfs artifact
curl -L \
-H "Accept: application/vnd.github+json" \
-H "Authorization: Bearer ${PAT_KJX_ARTIFACT}" \
-H "X-GitHub-Api-Version: 2022-11-28" \
"${INITRAMFS_URL}" \
-o "${FA_INITRAMFS_TARBALL}"

}

# Fetch the kernel/bzImage
fetch_kernel() {

set -e


# save the current list of artifacts
curl -H \
    "Authorization: token ${PAT_KJX_ARTIFACT}" \
    "${ARTIFACT_API_URI}" \
    | jq -C -r '.artifacts[]' > "${ARTIFACT_LIST_JSON}"


# Set kernel URI
KERNEL_URI=$(curl -H \
    "Authorization: token ${PAT_KJX_ARTIFACT}" \
    "${ARTIFACT_API_URI}" \
    | jq -C -r '.artifacts[]                | \
                select(.name == "kernel")   | \
                .archive_download_url'
#                | \
#                awk 'NR==1 {print $1}'
)

# Download artifact to path
 curl -L \
-H "Accept: application/vnd.github+json" \
-H "Authorization: Bearer ${PAT_KJX_ARTIFACT}" \
-H "X-GitHub-Api-Version: 2022-11-28" \
"${KERNEL_URI}" \
-o "${CICD_ART_PATH}/kernel.zip" && \

cd "${CICD_ART_PATH}" && \
unzip ./kernel.zip


# =====================================
# =====================================



}

# The artifact from dropbear
fetch_rootfs() {

set -e

set_vars

curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${PAT_KJX_ARTIFACT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
     "${ARTIFACT_API_URI}" > "${ARTIFACT_LIST_JSON}"


curl -L \
-H "Accept: application/vnd.github+json" \
-H "Authorization: Bearer ${PAT_KJX_ARTIFACT}" \
-H "X-GitHub-Api-Version: 2022-11-28" \
"${INITRAMFS_URL}" \
-o "${INITRAMFS_TARBALL}"

}

# The ISO9660 artifact
fetch_beetor_bwc() {

#make beetor
set -e
. ./scripts/ccr.sh; checker; \
docker pull registry:3.0
docker run -d -p 5000:5000 --name registry registry:3.0
docker start registry && \
docker compose -f ./compose.yml --progress=plain build beetor && \
docker compose images | grep beetor | awk '{ print $4 }' && \
docker push localhost:5000/beetor:latest && \
docker stop registry

}


fetch_runit() {

# download runit artifact
#

# organize under burn directory
set -e
docker run -d -p 5000:5000 --name registry registry:3.0
. ./scripts/ccr.sh; checker; \

docker compose -f ./compose.yml create beetor
mkdir -p ./artifacts/runitsv && \
docker cp runit:/app/runit.tar.gz ./artifacts/runitsv/ && \
chmod -c +rX ./artifacts/runitsv/beetor;
docker stop registry


}


# The ISO9660 artifact
fetch_isogen() {

set -e

set_vars

curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${PAT_KJX_ARTIFACT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
     "${ARTIFACT_API_URI}" > "${ARTIFACT_LIST_JSON}"


curl -L \
-H "Accept: application/vnd.github+json" \
-H "Authorization: Bearer ${PAT_KJX_ARTIFACT}" \
-H "X-GitHub-Api-Version: 2022-11-28" \
"${INITRAMFS_URL}" \
-o "${INITRAMFS_TARBALL}"

}

print_usage() {
cat <<-END >&2
USAGE: fa-gha [-options]
                - kernel
                - initramfs
                - ssh-rootfs
                - qonq-qdb
                - beetor
                - runit
                - iso
                - version
                - help
eg,
MODE="kernel"     . ./fa-gha   # Retrieve bzImage artifact from previous actions workflow
MODE="initramfs"  . ./fa-gha   # Retrieve initramfs artifact from previous actions workflow
MODE="ssh-rootfs" . ./fa-gha   # Retrieve dropbear-based ssh-enabled-rootfs artifact from previous actions workflow
MODE="qonq-qdb"   . ./fa-gha   # Retrieve qonq-qdb virtualization software artifact
MODE="beetor"     . ./fa-gha   # Retrieve beetor_bwc signal-based tracing orchestration from previous actions workflow
MODE="runit"      . ./fa-gha   # Retrieve runit service tree
MODE="iso"        . ./fa-gha   # Retrieve the ISO9660 file for the distro
MODE="version"    . ./fa-gha   # shows script version
MODE="help"       . ./fa-gha   # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-initramfs" ] || [ "$MODE" = "--initramfs" ] || [ "$MODE" = "initramfs" ]; then
    fetch_initramfs
elif [ "$MODE" = "-kernel" ] || [ "$MODE" = "--kernel" ] || [ "$MODE" = "kernel" ]; then
    fetch_kernel
elif [ "$MODE" = "-beetor" ] || [ "$MODE" = "--beetor" ] || [ "$MODE" = "beetor" ]; then
    fetch_beetor_bwc
elif [ "$MODE" = "-runit" ] || [ "$MODE" = "--runit" ] || [ "$MODE" = "runit" ]; then
    fetch_runit
elif [ "$MODE" = "-iso" ] || [ "$MODE" = "--iso" ] || [ "$MODE" = "iso" ]; then
    # if [ -z "${FILE_PATH}" ]; then
    #     return # unconditional branch
    # fi
    # main logic
    #fa-gha "${FILE_PATH}"
    fetch_isogen
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "\n|> Version: "
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi


