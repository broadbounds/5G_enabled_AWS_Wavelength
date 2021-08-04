# https://aws.amazon.com/blogs/compute/deploying-your-first-5g-enabled-application-with-aws-wavelength/

# We set AWS as the cloud platform to use
provider "aws" {
   region  = var.aws_region
   access_key = var.access_key
   secret_key = var.secret_key
 }

# We create a new VPC
resource "aws_vpc" "vpc" {
   cidr_block = "10.0.0.0/16"
   instance_tenancy = "default"
   tags = {
      Name = "VPC"
   }
   enable_dns_hostnames = true
}

# We create an internet gateway
# Allows communication between our VPC and the internet
resource "aws_internet_gateway" "internet_gateway" {
   depends_on = [
      aws_vpc.vpc,
   ]
   vpc_id = aws_vpc.vpc.id
   tags = {
      Name = "internet-gateway",
   }
}

# We add a carrier gateway
resource "aws_ec2_carrier_gateway" "carrier_gateway" {
 depends_on = [
      aws_vpc.vpc,
  ]   
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "carrier-gateway"
  }
}


# We create a security group for SSH traffic
# EC2 instances' firewall that controls incoming and outgoing traffic
resource "aws_security_group" "sg_bastion_host" {
   depends_on = [
      aws_vpc.vpc,
   ]
   name = "sg bastion host"
   description = "bastion host security group"
   vpc_id = aws_vpc.vpc.id
   ingress {
      description = "allow access via ssh"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
      description = "allow access to web server"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }   
   ingress {
      description = "allow access to cloudMapper"
      from_port = 8000
      to_port = 8000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }
   egress {
      description = "allow all outbound traffic to anywehere"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "sg bastion host"
   }
}



# We create a security group for the API server
# EC2 instances' firewall that controls incoming and outgoing traffic
resource "aws_security_group" "sg_api_server" {
   depends_on = [
      aws_vpc.vpc,
   ]
   name = "sg API server"
   description = "API server security group"
   vpc_id = aws_vpc.vpc.id
   ingress {
      description = "allow access via ssh from the Bastion SG"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
      description = "allow access to accept incoming API requests"
      from_port = 5000
      to_port = 5000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }
   egress {
      description = "allow all outbound traffic to anywehere"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "sg API server"
   }
}



# We create a security group for the API server
# EC2 instances' firewall that controls incoming and outgoing traffic
resource "aws_security_group" "sg_inference_server" {
   depends_on = [
      aws_vpc.vpc,
   ]
   name = "sg Inference server"
   description = "Inference server security group"
   vpc_id = aws_vpc.vpc.id
   ingress {
      description = "allow access via ssh from the Bastion SG"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
      description = "allow access from API server"
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
      description = "allow access from API server"
      from_port = 8081
      to_port = 8081
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }   
   egress {
      description = "allow all outbound traffic to anywehere"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "sg Inference server"
   }
}


# We must first request access to the the Wavelength Zone at this link
# https://pages.awscloud.com/wavelength-signup-form.html
# Then select the region and enable the Wavelength Zone at the link:
# https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Settings:tab=zones
# We create a private subnet for the Wavelength Zone
# Instances will not be accessible via the internet gateway
resource "aws_subnet" "private_subnet" {
   depends_on = [
      aws_vpc.vpc,
   ]
   vpc_id = aws_vpc.vpc.id
   cidr_block = "10.0.0.0/24"
   availability_zone_id = var.WL_ZONE
   tags = {
      Name = "private-subnet-wavelength-zone"
   }
}


# We create an elastic IP 
# A static public IP address that we can assign to any EC2 instance
resource "aws_eip" "elastic_ip" {
   vpc = true
}

# We create a NAT gateway with a required public IP
# Lives in a public subnet and prevents externally initiated traffic to our private subnet
# Allows initiated outbound traffic to the Internet or other AWS services
resource "aws_nat_gateway" "nat_gateway" {
   depends_on = [
      aws_subnet.public_subnet,
      aws_eip.elastic_ip,
   ]
   allocation_id = aws_eip.elastic_ip.id
   subnet_id = aws_subnet.public_subnet.id
   tags = {
      Name = "nat-gateway"
   }
}

# We create a route table with target as NAT gateway and destination as "internet"
# Set of rules used to determine where network traffic is directed
resource "aws_route_table" "NAT_route_table" {
   depends_on = [
      aws_vpc.vpc,
      aws_nat_gateway.nat_gateway,
   ]
   vpc_id = aws_vpc.vpc.id
   route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.nat_gateway.id
   }
   tags = {
      Name = "NAT-route-table"
   }
}

# We associate our route table to the private subnet
# Keeps the subnet private because it has a route to the internet via our NAT gateway 
resource "aws_route_table_association" "associate_routetable_to_private_subnet" {
   depends_on = [
      aws_subnet.private_subnet,
      aws_route_table.NAT_route_table,
   ]
   subnet_id = aws_subnet.private_subnet.id
   route_table_id = aws_route_table.NAT_route_table.id
}





# We create a public subnet for our web server and bastion host
# Instances will have a dynamic public IP and be accessible via the internet gateway
resource "aws_subnet" "public_subnet" {
   depends_on = [
      aws_vpc.vpc,
   ]
   vpc_id = aws_vpc.vpc.id
   cidr_block = "10.0.1.0/24"
   availability_zone_id = "use1-az1"  #"use2-az1"
   tags = {
      Name = "public-subnet-web-server-bastion-host"
   }
   map_public_ip_on_launch = true
}





# We create a route table with target as our internet gateway and destination as "internet"
# Set of rules used to determine where network traffic is directed
resource "aws_route_table" "IG_route_table" {
   depends_on = [
      aws_vpc.vpc,
      aws_internet_gateway.internet_gateway,
   ]
   vpc_id = aws_vpc.vpc.id
   route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.internet_gateway.id
   }
   tags = {
      Name = "IG-route-table"
   }
}

# We associate our route table to the public subnet
# Makes the subnet public because it has a route to the internet via our internet gateway
resource "aws_route_table_association" "associate_routetable_to_public_subnet" {
   depends_on = [
      aws_subnet.public_subnet,
      aws_route_table.IG_route_table,
   ]
   subnet_id = aws_subnet.public_subnet.id
   route_table_id = aws_route_table.IG_route_table.id
}




# We create an ssh key using the RSA algorithm with 4096 rsa bits
# The ssh key always includes the public and the private key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# We upload the public key of our created ssh key to AWS
resource "aws_key_pair" "public_ssh_key" {
  key_name   = var.public_key_name
  public_key = tls_private_key.ssh_key.public_key_openssh

   depends_on = [tls_private_key.ssh_key]
}

# We save our public key at our specified path.
# Can upload on remote server for ssh encryption
resource "local_file" "save_public_key" {
  content = tls_private_key.ssh_key.public_key_openssh 
  filename = "${var.key_path}${var.public_key_name}.pem"
}

# We save our private key at our specified path.
# Allows private key instead of a password to securely access our instances
resource "local_file" "save_private_key" {
  content = tls_private_key.ssh_key.private_key_pem
  filename = "${var.key_path}${var.private_key_name}.pem"
}




# We create an elastic IP 
# A static public IP address that we can assign to our bastion host
resource "aws_eip" "bastion_elastic_ip" {
   vpc = true
}


# We create an elastic IP 
# A static public IP address that we can assign to our API server
resource "aws_eip" "api_elastic_ip" {
   vpc = true
}


# We create an elastic IP 
# A static public IP address that we can assign to our Inference server
resource "aws_eip" "inference_elastic_ip" {
   vpc = true
}



# We create a bastion host
# Allows SSH into instances in private subnet
resource "aws_instance" "bastion_host" {
   depends_on = [
      aws_security_group.sg_bastion_host,
   ]
   ami = var.BASTION_IMAGE_ID
   instance_type = "t3.medium"
   key_name = aws_key_pair.public_ssh_key.key_name
   vpc_security_group_ids = [aws_security_group.sg_bastion_host.id]
   subnet_id = aws_subnet.public_subnet.id
   user_data = "" 
   tags = {
      Name = "bastion host"
   }
   provisioner "file" {
    source      = "${var.key_path}${var.private_key_name}.pem"
    destination = "/home/ec2-user/private_ssh_key.pem"

    connection {
    type     = "ssh"
    user     = "bitnami"
    private_key = tls_private_key.ssh_key.private_key_pem
    host     = aws_instance.bastion_host.public_ip
    }
  }
}


# We associate the elastic ip to our bastion host
resource "aws_eip_association" "bastion_eip_association" {
  instance_id   = aws_instance.bastion_host.id
  allocation_id = aws_eip.bastion_elastic_ip.id
}




# We create the API server
# Allows 
resource "aws_instance" "api_server" {
   depends_on = [
      aws_security_group.sg_api_server,
   ]
   ami = var.API_IMAGE_ID
   instance_type = "t3.medium"
   key_name = aws_key_pair.public_ssh_key.key_name
   vpc_security_group_ids = [aws_security_group.sg_api_server.id]
   subnet_id = aws_subnet.private_subnet.id
   user_data = "" 
   tags = {
      Name = "api server"
   }
   provisioner "file" {
    source      = "${var.key_path}${var.private_key_name}.pem"
    destination = "/home/ec2-user/private_ssh_key.pem"

    connection {
    type     = "ssh"
    user     = "bitnami"
    private_key = tls_private_key.ssh_key.private_key_pem
    host     = aws_instance.api_server.public_ip
    }
  }
}


# We associate the elastic ip to our bastion host
resource "aws_eip_association" "api_eip_association" {
  instance_id   = aws_instance.api_server.id
  allocation_id = aws_eip.api_elastic_ip.id
}




# We create a inference server
# Allows 
resource "aws_instance" "inference_server" {
   depends_on = [
      aws_security_group.sg_inference_server,
   ]
   ami = var.INFERENCE_IMAGE_ID
   instance_type = "g4dn.2xlarge"
   key_name = aws_key_pair.public_ssh_key.key_name
   vpc_security_group_ids = [aws_security_group.sg_inference_server.id]
   subnet_id = aws_subnet.private_subnet.id
   user_data = "" 
   tags = {
      Name = "inference server"
   }
   provisioner "file" {
    source      = "${var.key_path}${var.private_key_name}.pem"
    destination = "/home/ec2-user/private_ssh_key.pem"

    connection {
    type     = "ssh"
    user     = "bitnami"
    private_key = tls_private_key.ssh_key.private_key_pem
    host     = aws_instance.inference_server.public_ip
    }
  }
}


# We associate the elastic ip to our bastion host
resource "aws_eip_association" "inference_eip_association" {
  instance_id   = aws_instance.inference_server.id
  allocation_id = aws_eip.inference_elastic_ip.id
}






