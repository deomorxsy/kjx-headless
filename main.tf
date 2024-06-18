provider "aws" {
  region = "${TOFU_AWS_REGION}"
}
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${TOFU_AWS_VPC}"
  }
}
resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.${TOFU_AWS_MYPVC_ID}
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "$TOFU_AWS_SUBNET"
  }
}
resource "aws_instance" "kjx_headless_base" {
  ami           = "${TOFU_AWS_CUSTOM_AMI}"
  instance_type = "t2.micro"
  subnet_id     = "${TOFU_AWS_SUBNET_ID}aws_subnet.mysubnet.id"
  tags = {
    Name = "kjxh2024_${CUSTOM_AMI_VERSION}"
  }
  provisioner "distro-deploy" {
    command = "sleep 600 && aws ec2 terminate-instances --instance-ids ${self.id}"
  }
}

output ""
