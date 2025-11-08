#!/bin/sh

set_vars() {

if [ "${GITHUB_ACTIONS}" = "true" ]; then

FETCH_ARTIFACT="\${{ secrets.FETCH_ARTIFACT }}"
ARTIFACT_API_URI="https://api.github.com/repos/deomorxsy/kjx-headless/actions/artifacts/"
ARTIFACT_LIST_JSON="./artifacts/ci-cd/artifact-list.json"

# tarballs
INITRAMFS_TARBALL="./artifacts/new-initramfs.cpio.gz"
BZIMAGE=""

INITRAMFS_URL=$(cat <<EOF
cat ${ARTIFACT_LIST_JSON} | jq -r '.artifacts | map(select(.name == "kernel")) | sort_by(.created_at) | last | .archive_download_url'
EOF
)

else
    printf "\n|> Error: this is NOT a workflow runner from Github Actions. This script leverages Actions' secrets management. Exiting now...\n\n"
fi


}

fetch() {

set -e

set_vars

curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${FETCH_ARTIFACT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
     "${ARTIFACT_API_URI}" > "${ARTIFACT_LIST_JSON}"


curl -L \
-H "Accept: application/vnd.github+json" \
-H "Authorization: Bearer ${FETCH_ARTIFACT}" \
-H "X-GitHub-Api-Version: 2022-11-28" \
"${INITRAMFS_URL}" \
-o "${INITRAMFS_TARBALL}"

}
