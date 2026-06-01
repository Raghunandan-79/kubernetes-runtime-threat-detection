# key pair
resource "aws_key_pair" "my_key" {
  key_name   = "${var.env}-terra-key-ec2"
  public_key = file("terra-key-ec2.pub")

  tags = {
    Enviroment = var.env
  }
}

# VPC and Security Group
resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "my_group" {
  name        = "${var.env}-automate-sg"
  description = "This will add a TF generated security group"
  vpc_id      = aws_default_vpc.default.id

  # inbound rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH Open"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP Open"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Notes App"
  }

  # outbount rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-automate-sg"
  }
}

# ec2 instance
resource "aws_instance" "my_instance" {
  depends_on = [
    aws_security_group.my_group,
    aws_key_pair.my_key
  ]

  key_name        = aws_key_pair.my_key.key_name
  security_groups = [aws_security_group.my_group.name]
  instance_type   = "t2.micro"
  ami             = var.ec2_ami_id

  user_data = file("user-data.sh")

  root_block_device {
    volume_size = var.env == "prd" ? 20 : var.ec2_root_storage_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.env}-automated-ec2"
  }
}