FROM alpine:3.22 AS builder

COPY ./scripts/formalize/agda-setup.sh ./scripts/formalize/agda-setup.sh

# Add ghcup's bin directory to the PATH so that the versions of GHC it builds
# are available in the build layers
ENV GHCUP_INSTALL_BASE_PREFIX=/
#ENV PATH="/home/${PANDOCADA_USER}/.ghcup/bin:${PATH}


RUN <<EOF

handler(){

if ! (MODE="pandoc-tarball" . /app/scripts/pandoc-setup.sh); then
    printf "\n|> Error: could not execute the [pandoc-tarball] function from the pandoc-setup.sh shellscript. Exiting now...\n\n"
    return 1
fi
printf "\n|> Succesfully run [pandoc-tarball] from pandoc-setup.sh. Proceeding..."

if ! (ls -allhtr "/pandoc-tarball-pkg.tar.gz"); then
    echo "|> pandoc-tarball NOT FOUND. EXITING..."
    return 1
fi
echo "|> FOUND THE SO TARBALL \O/ ...[PASSED]"

}

handler

EOF



### # run tests
### WORKDIR /app
### COPY . .
### RUN ls -allhtr
### RUN <<EOF
### haskell_tests() {
### for dir in /app/*; do
###     if [ -d $dir ]; then
###     cd "$dir" && stack init --force && \
###     cat ./stack.yaml && \
###     stack build --test >> /app/test_result_"$(basename "$dir")"_.txt 2>&1
###     cd - || return
###     elif [ -f $dir ]; then
###         echo "A file $dir was found. Skipping..."
###     fi
### done
### }
### haskell_tests
### EOF

#RUN cd /app/hello-world/ && ls -allhtr
#RUN stack init && cat ./stack.yaml
#RUN stack build --test >> /app/test_result.txt 2>&1

# stack test
#> /app/test_result.txt 2>&1


# ======================
# 2. Relay Step
# ======================
FROM alpine:3.20 as relay

WORKDIR /tests

# COPY --from=builder /app/test_result_*_.txt .
COPY --from=builder /pandoc-tarball-pkg.tar.gz

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["printf \"===== UNIT TEST =====\\n\\n\" && for index in /tests/*; do cat $index && echo && echo done"]


### # ======================
### # 3. Artifact Step
### # ======================
### FROM alpine:3.20 as art
###
### WORKDIR /art
###
### # COPY --from=builder /app/test_result_*_.txt .
### COPY --from=builder /pandoc-tarball-pkg.tar.gz /art/pandoc-tarball-pkg.tar.gz

# set command to be executed when the container starts
#ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
#CMD ["printf \"===== UNIT TEST =====\\n\\n\" && for index in /tests/*; do cat $index && echo && echo done"]
