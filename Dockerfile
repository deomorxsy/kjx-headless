# ==================
# 1. Builder Step
# ==================

FROM alpine:3.20 as builder

RUN <<"EOF"
apk upgrade && apk update && \
apk add python3 musl-dev iasl \
    sparse xen-dev sphinx ninja git make bash fuse3-dev && \
mkdir -p downloads && \
cd downloads/ && \
wget https://download.qemu.org/qemu-9.1.0.tar.bz2 && \
tar -xvf qemu-9.1.0.tar.bz2 && \
cd qemu-9.1.0/ && \
./configure --disable-kvm \
    --enable-fuse \
    --target-list="x86_64-softmmu" \
    --prefix="/usr" \
    --localstatedir="/var" \
    --sysconfdir="/etc" \
    --disable-pa && \
make -j$(nproc) && \
make install

# for each qemu program, get track of its dependent shared objects
for f in /usr/bin/*; do
    case $f in
        /usr/bin/qemu*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >> /foo.txt ;;
    esac
done


# ==== follow softlinks of the filepaths with readlink

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
RUN printf "\n===== Currently on /app/qemu-shared-objects directory ======\n\n"
RUN tar -xvf /app/shared_deps/archive.tar.gz && \
    rm /app/shared_deps/archive.tar.gz && \
    cp -r ./* /


WORKDIR /app
RUN ls -allht
RUN printf "\n===== Currently on /app directory ======\n\n"
RUN chmod +x /app/scripts/squashed.sh
RUN ls -allht

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# qemu qemu-img qemu-system-x86_64
# qemu-utils on ubuntu
# set argument to be fed to the entrypoint
CMD ["apk upgrade && apk update && \
    apk add libcap parted device-mapper fuse-overlayfs qemu qemu-img qemu-system-x86_64 \
        file multipath-tools e2fsprogs xorriso expect libseccomp libcgroup \
        perl runit openssh git && \
    setcap cap_sys_admin,cap_dac_override+eip $(readlink -f $(which qemu-img)) && \
    setcap cap_sys_admin+eip $(readlink -f $(which parted)) && \
    setcap cap_sys_admin,cap_dac_override,cap_dac_read_search+eip $(readlink -f $(which kpartx)) && \
    setcap cap_sys_admin+eip $(readlink -f $(which mkfs.ext4)) && \
    setcap cap_sys_admin,cap_dac_override+ep $(readlink -f $(which losetup)) && \
    . /app/scripts/squashed.sh"]



