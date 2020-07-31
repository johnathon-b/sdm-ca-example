provider "aws" {
}

variable "sdm_pub" {}

data "template_file" "cloud-init-yaml" {
    template = file("${path.module}/files/cloud-init.yaml")
    vars = {
      sdm_pub_key = var.sdm_pub
    }
}

resource "aws_security_group" "ca-example" {
  name        = "ca-example"
  description = "Allow HTTP, HTTPS and SSH traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SDM"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ca-example"
  }
}



resource "aws_instance" "ubuntu-ca" {
  ami           = "ami-03ba3948f6c37a4b0"
  instance_type = "t2.micro"
  user_data = data.template_file.cloud-init-yaml.rendered

  tags = {
    Name = "ubuntu"
  }

  vpc_security_group_ids = [
    aws_security_group.ubuntu.id
  ]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 30
  }
}

resource "aws_eip" "ubuntu-ca" {
  vpc      = true
  instance = aws_instance.ubuntu.id
}

resource "sdm_resource" "ssh_cert" {
    depends_on = [
        aws_eip.ubuntu-ca
    ]
    ssh_cert {
        name = "ubuntu-ca"
        hostname = aws_eip.ubuntu.public_ip
        username = "sdm"
        port = 22
    }
}