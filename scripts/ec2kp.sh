#!/bin/sh

setup_ec2() { # tofu_deps container
    # create keypair
    printf "|> Creating keypair..."
    awslocal ec2 create-key-pair \
    --key-name my-key \
    --query 'KeyMaterial' \
    --output text | tee key.pem
}

# start localstack emulation
start_ec2() { # localstack container
    export TOFU_AWS_REGION="us-east-1"
    export TOFU_AWS_VPC="MyVPC"
    export TOFU_AWS_MYPVC_ID="my-vpc"
    export TOFU_AWS_SUBNET="MySubnet"
    export TOFU_AWS_SUBNET_ID="subnet-12345"
    export TOFU_AWS_CUSTOM_AMI="ami-12345678"
    export CUSTOM_AMI_VERSION="v1.0"
    export AWS_INSTANCE_ID="kjx_headless_base"
    export AWS_BUCKET="my-bucket"

    . ./scripts/ccr.sh; checker && \
    docker run -d -p 5000:5000 --name registry registry:latest && \
    docker compose -f ./compose.yml --progress=plain build localstack && \
    docker push localhost:5000/localstack:latest && \
    docker compose -f ./compose.yml up localstack && \
    opentofu init
    opentofu apply

    unset TOFU_AWS_REGION
    unset TOFU_AWS_VPC
    unset TOFU_AWS_MYPVC_ID
    unset TOFU_AWS_SUBNET
    unset TOFU_AWS_SUBNET_ID
    unset TOFU_AWS_CUSTOM_AMI
    unset CUSTOM_AMI_VERSION
    unset AWS_INSTANCE_ID
    unset AWS_BUCKET
}

# check localstack config
check_ec2() { # tofu_deps container
    awslocal ec2 describe-instances --endpoint-url=http://localhost:4566
    awslocal ec2 describe-vpcs --endpoint-url=http://localhost:4566
    awslocal s3 ls --endpoint-url=http://localhost:4566
}

setup_ec2
start_ec2
check_ec2
