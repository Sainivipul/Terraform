resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
  tags= {
  name = "project_vpc"
   }
}


resource "aws_subnet" "sub1"{

  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet1"
  }

}



resource "aws_subnet" "sub2"{


  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet2"
  }

}

resource "aws_internet_gateway" "igw" {

vpc_id = aws_vpc.myvpc.id

}

resource "aws_route_table" "RT"{

vpc_id = aws_vpc.myvpc.id

route{
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id

    }

}

resource "aws_route_table_association" "rtal"{ 
 subnet_id = aws_subnet.sub1.id
 route_table_id = aws_route_table.RT.id

}

resource "aws_route_table_association" "rtal2"{
 subnet_id = aws_subnet.sub2.id
 route_table_id = aws_route_table.RT.id

 }


resource "aws_security_group" "allow_tls" {
  name        = "websg"
  description = "Allow websg inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      =["0.0.0.0/0"]
   }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      =["0.0.0.0/0"]
   }

  egress {
      from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
   }

  tags = {
    Name = "Web_SG"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "kumbakumba"
}


resource "aws_instance" "webtesting" {
  ami           = "ami-0261755bbcb8c4a84"
  instance_type = "t2.micro"
 vpc_security_group_ids = [aws_security_group.allow_tls.id]
 subnet_id = aws_subnet.sub1.id
user_data = <<-EOF
#!/bin/bash
apt update
apt install -y apache2
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
apt install -y awscli
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>My Portfolio</title>
  <style>
    /* Add animation and styling for the text */
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
  </head>
<body>
  <h1>Terraform Project Server 1</h1>
  <h2>Instance ID: <span style="color:green">$INSTANCE_ID</span></h2>
  <p>Welcome to vipul Saini Project </p>

</body>
</html>
   EOF
 tags = {
    Name = "Project_instance"
  }
}


resource "aws_instance" "webtesting2" {
  ami           = "ami-0261755bbcb8c4a84"
  instance_type = "t2.micro"
 vpc_security_group_ids = [aws_security_group.allow_tls.id]
 subnet_id = aws_subnet.sub2.id
user_data = <<-EOF
#!/bin/bash
apt update
apt install -y apache2
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
apt install -y awscli
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>My Portfolio</title>
  <style>
    /* Add animation and styling for the text */
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
  </head>
<body>
  <h1>Terraform Project Server 1</h1>
  <h2>Instance ID: <span style="color:green">$INSTANCE_ID</span></h2>
  <p>Welcome to vipul Saini Project </p>

</body>
</html>

</html>
   EOF




 tags = {
    Name = "Project_instnce2"
  }
}


resource "aws_lb" "myalb" {
 name = "project-alb"
 internal = false
load_balancer_type = "application"
security_groups= [aws_security_group.allow_tls.id]
subnets= [aws_subnet.sub1.id, aws_subnet.sub2.id]
 tags = {
  name="webLB"
  }
}

 resource "aws_lb_target_group" "my_tg"{
  name = "my-tg"
  port = 80
  protocol = "HTTP"
 vpc_id = aws_vpc.myvpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
   target_group_arn = aws_lb_target_group.my_tg.arn
target_id = aws_instance.webtesting.id
port = 80

}


resource "aws_lb_target_group_attachment" "attach2" {
target_group_arn = aws_lb_target_group.my_tg.arn
target_id = aws_instance.webtesting2.id
port = 80

}

resource "aws_lb_listener" "listener"{

load_balancer_arn= aws_lb_target_group.my_tg.arn
port = 80
protocol = "HTTP"

default_action {

target_group_arn = aws_lb_target_group.my_tg.arn
type = "forword"
}
}

output "loadbalancerdns" {
value = aws_lb.myalb.dns_name
} 