provider "aws" {
    region = "eu-west-2"
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

resource "aws_vpc" "mainvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.name}.tf.vpc"
  }
}

# Create public sub
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}.public.subnet"
  }
}

resource "aws_security_group" "mysecuritygroup" {
    name        = "mysecuritygroup"
    description = "access ssh and httpx"
    vpc_id      = aws_vpc.mainvpc.id

  ingress {
    description = "http"
    from_port = 80 
    to_port = 80 
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    to_port = 0 
    from_port = 0
    protocol = -1 
    cidr_blocks = ["0.0.0.0/0"]
    }
  tags = {
        Name = "${var.name}.securitygroup"
    }
}

# Create an igw
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mainvpc.id
  tags = {
    Name = "${var.name}.my.internet.gateway"
  }
}

# Creating a route table
resource "aws_route_table" "routepublic" {
  vpc_id = aws_vpc.mainvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.name}.my.route.table"
  }
}

# Route table associations
resource "aws_route_table_association" "routeapp" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.routepublic.id
}

# resource "aws_route_table_association" "routeappA" {
#   subnet_id = aws_subnet.subpublicA.id
#   route_table_id = aws_route_table.routepublic.id
# }

resource "aws_instance" "myDockerInstance" {
    ami = var.ami_app
      instance_type = "t2.micro"
      key_name = var.ssh_key
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.mysecuritygroup.id]
    private_ip = "10.0.1.10"   // Ansible will need this IP to communicate to the machine via an SSH key
    associate_public_ip_address = true
    tags = {    
        Name = "DockerInstance" 
    }
}

resource "aws_instance" "myAnsibleInstance" {
	ami = var.ami_app
	instance_type = "t2.micro"
	key_name = var.ssh_key
	subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.mysecuritygroup.id]
    associate_public_ip_address = true
    user_data = "${file("./ansible-install.sh")}"

  # depends_on = [aws_instance.jenkins, aws_instance.deploy]

  tags = {	
		Name = "ansible"	
	}
}

output "dockerInstance" {
  value = aws_instance.myDockerInstance.public_ip
}

output "AnsibleInstance" {
  value = aws_instance.myAnsibleInstance.public_ip
}