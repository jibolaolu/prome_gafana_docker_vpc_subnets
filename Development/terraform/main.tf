//create vpc
//create internet gateway
//create custom route table
//create a subnet
//associate subnet with route table
//create security group to allow port 22, 80 , 443
//create a network interface with an ip in the subnet that was created
//create ubuntu server and install apache2 and enable

//create vpc
resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.8.0.0/16"
  tags = {
    Name = "development"
  }
}

//create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dev-vpc.id
}

//create custom route table
resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "development"
  }
}

//create a subnet

resource "aws_subnet" "subnet-public" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "10.8.1.0/24"
  availability_zone = "eu-west-1c"
  map_public_ip_on_launch = true
  tags = {
    Name ="dev-subnet-public"
  }
}

resource "aws_subnet" "subnet-private" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "10.8.2.0/24"
  availability_zone = "eu-west-1c"
  map_public_ip_on_launch = true
  tags = {
    Name ="dev-subnet-private"
  }
}

//associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-public.id
  route_table_id = aws_route_table.dev-route-table.id
}


//create security group to allow port 22, 80 , 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description = "HTTP"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "HTTP"
    from_port   = 3000
    to_port     = 3000
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
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_web"
  }
}

//create a network interface with an ip in the subnet that was created
resource "aws_network_interface" "webserver-kenny" {
subnet_id       = aws_subnet.subnet-public.id
security_groups = [aws_security_group.allow_web.id]
  }


resource "aws_instance" "grafana" {
  ami           = var.GRAFANA_TO_DEPLOY
  instance_type = "t2.micro"
  key_name      = "mac-ireland"
  subnet_id     = aws_subnet.subnet-public.id
  availability_zone= "eu-west-1c"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  tags = {
    Name        = "grafana"
  }
}

resource "aws_instance" "prometheus" {
  ami           = var.PROMETHEUS_TO_DEPLOY
  instance_type = "t2.micro"
  key_name      = "mac-ireland"
  subnet_id     = aws_subnet.subnet-private.id
  availability_zone= "eu-west-1c"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  tags = {
    Name        = "internal-server-prometeus"
  }
}

