#
# prepare the QEMU binaries
# for the VM environment
#

# ==================
# 1. Builder Step
# ==================

FROM alpine:3.20 as builder

WORKDIR /app/

RUN <<"EOF"

# extract with -xJvf
#qemuver="qemu-9.2.3.tar.xz"

tarformat=".tar.bz2"
# extract .tar.bz2 with xvf
newver="qemu-9.2.3"
oldver="qemu-9.1.0"

apk upgrade && apk update && \
apk add python3 musl-dev iasl \
    sparse xen-dev sphinx ninja git make bash fuse3-dev && \

mkdir -p downloads
cd downloads/ || return
wget https://download.qemu.org/"$newver.tar.bz2" && \
tar -xvf "$newver.tar.bz2" && \
cd "$newver"/ && printf "\n\n|> OK!! in dir!!\n"

./configure --disable-kvm \
    --enable-fuse \
    --target-list="x86_64-softmmu" \
    --prefix="/usr" \
    --localstatedir="/var" \
    --sysconfdir="/etc" \
    --disable-pa && \
make -j$(( $(nproc)-1 )) && \
make install
EOF

# for each qemu program, get track of its dependent shared objects
RUN <<EOF
for f in /usr/bin/*; do
    case $f in
        /usr/bin/qemu*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >> /foo.txt ;;
    esac
done

EOF


# ==== follow softlinks of the filepaths with readlink
RUN <<EOF

# set IFS: input field separator
IFS='\n\t'

# read each line defining the input field separator,
# follow the soft link and append readlink output line to a new file
while IFS= read -r line; do
    readlink -f "$line" >> /bar.txt
done < /foo.txt

# remove new lines on the lists, then create new file
sed '/^$/d' /foo.txt > /foobar.txt
sed '/^$/d' /bar.txt >> /foobar.txt

# then remove duplicate shared objects
sort /foobar.txt | uniq > /quux.txt

# generate a tarball of shared objects from filepaths on a text file
tar -czf /archive.tar.gz -T /quux.txt


EOF

#ENTRYPOINT ["/bin/sh", "-c"]

# ==================
# 2. relay step
# ==================
FROM alpine:3.20 as relay

WORKDIR /app

COPY "./artifacts/" /app/artifacts/
COPY "./scripts/" /app/scripts/
COPY "./tests/" /app/tests/
COPY --from=builder "/usr/bin/qemu*" /usr/bin/
COPY --from=builder "/archive.tar.gz" /app/shared_deps/

WORKDIR /app/shared_deps
RUN printf "\n===== Currently on /app/shared_deps directory ======\n\n"
RUN tar -xvf /app/shared_deps/archive.tar.gz && \
    rm /app/shared_deps/archive.tar.gz && \
    cp -r ./* /


WORKDIR /app
RUN ls -allht
RUN printf "\n===== Currently on /app directory ======\n\n"
RUN chmod +x /app/scripts/squashed.sh

RUN chmod +x /app/scripts/full.sh

RUN ls -allht





FROM alpine:3.20 as final

COPY --from=relay "/usr/bin/qemu*" /usr/bin/
COPY --from=relay "/app/shared_deps/lib/*" /lib/
COPY --from=relay "/app/shared_deps/usr/lib/*" /usr/lib/

COPY --from=builder "/archive.tar.gz" /app/shared_deps/

WORKDIR /app/shared_deps
RUN printf "\n===== Currently on /app/shared_deps directory ======\n\n"
RUN tar -xvf /app/shared_deps/archive.tar.gz && \
    rm /app/shared_deps/archive.tar.gz && \
    cp -r ./* /



RUN <<EOF

/usr/bin/qemu-storage-daemon -h
/usr/bin/qemu-system-x86_64 -h

EOF



# =========
# new dependencies
# =============

FROM alpine:3.20 as otherdeps

COPY --from=relay "/usr/bin/qemu*" /usr/bin/
COPY --from=relay "/app/shared_deps/lib/*" /lib/
COPY --from=relay "/app/shared_deps/usr/lib/*" /usr/lib/

COPY --from=builder "/archive.tar.gz" /app/shared_deps/

RUN <<EOF

apk upgrade && apk update && \
    apk add libcap parted device-mapper fuse-overlayfs qemu qemu-img qemu-system-x86_64 \
        file multipath-tools e2fsprogs xorriso expect libseccomp libcgroup \
        perl runit openssh git

EOF


WORKDIR /app

RUN <<EOF

# below, use the same strategy but now without the dependencies used for the qemu build.

for f in /usr/bin/*; do
    case $f in
        /usr/bin/qemu*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >> /foo.txt ;;
        "$(readlink -f "$(which setcap)" )"      ) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >> /foo.txt ;;
        "$(readlink -f "$(which parted)" )"      ) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >> /foo.txt ;;
        "$(readlink -f "$(which kpartx)" )"      ) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >> /foo.txt ;;
        "$(readlink -f "$(which mkfs.ext4)" )"   ) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >> /foo.txt ;;
        "$(readlink -f "$(which losetup)" )"     ) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >> /foo.txt ;;
    esac
done

EOF

# ==== follow softlinks of the filepaths with readlink
RUN <<EOF

# set IFS: input field separator
IFS='\n\t'

# read each line defining the input field separator,
# follow the soft link and append readlink output line to a new file
while IFS= read -r line; do
    readlink -f "$line" >> /bar.txt
done < /foo.txt

# remove new lines on the lists, then create new file
sed '/^$/d' /foo.txt > /foobar.txt
sed '/^$/d' /bar.txt >> /foobar.txt

# then remove duplicate shared objects
sort /foobar.txt | uniq > /quux.txt

# generate a tarball of shared objects from filepaths on a text file
tar -czf /archive.tar.gz -T /quux.txt


EOF



# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# qemu qemu-img qemu-system-x86_64
# qemu-utils on ubuntu
# set argument to be fed to the entrypoint
#CMD ["apk upgrade && apk update && \
#    apk add libcap parted device-mapper fuse-overlayfs qemu qemu-img qemu-system-x86_64 \
#        file multipath-tools e2fsprogs xorriso expect libseccomp libcgroup \
#        perl runit openssh git && \
#    setcap cap_sys_admin,cap_dac_override+eip $(readlink -f $(which qemu-img)) && \
#    setcap cap_sys_admin+eip $(readlink -f $(which parted)) && \
#    setcap cap_sys_admin,cap_dac_override,cap_dac_read_search+eip $(readlink -f $(which kpartx)) && \
#    setcap cap_sys_admin+eip $(readlink -f $(which mkfs.ext4)) && \
#    setcap cap_sys_admin,cap_dac_override+ep $(readlink -f $(which losetup)) && \
#    . /app/scripts/squashed.sh"]


CMD ["echo", "hullo"]
