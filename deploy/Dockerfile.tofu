# Localstack Dockerfile for terraform ci
FROM python:3.12.5-alpine3.20

WORKDIR /usr/src/app

# install opentofu
RUN apk update && apk add --upgrade "wget" && \
    wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh && \
    chmod +x install-opentofu.sh && \
    ./install-opentofu.sh --install-method apk && \
    rm -f install-opentofu.sh

# install awscli-local
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install pyenv && \
    pyenv install 3.4.4 && \
    pyenv virtualenv 3.4.4 localaws && \
    pyenv activate localaws && \
    python3 -m pip install && \
    pip install awscli-local && \
    pyenv which python && \
    deactivate


RUN echo && \
# ======== set keypair ===========
cat > /usr/src/app/set_kp.sh  <<"EOF"
#!/bin/sh

# activates virtualenv with pyenv
pyenv activate localaws
which python

# create keypair
printf "|> Creating keypair..."
awslocal ec2 create-key-pair \
--key-name my-key \
--query 'KeyMaterial' \
--output text | tee tofu-key.pem

# set permissions to the keypair
chmod 400 /usr/src/app/tofu-key.pem

# deactivates virtualenv
deactivate
EOF && \
    chmod +x /usr/src/app/set_kp.sh && \
    source /usr/src/app/set_kp.sh
