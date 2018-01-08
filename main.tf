# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "${var.aws_vpc_cidr}"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create an external subnet for the security layer facing internet
resource "aws_subnet" "external" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.aws_external_subnet_cidr}"
  map_public_ip_on_launch = true
  tags {
    Name = "Terraform_external"
  }
}
# Create a subnet to launch our instances into
resource "aws_subnet" "web" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.aws_webserver_subnet_cidr}"
  tags {
    Name = "Terraform_web"
  }
}
# Create a subnet for LB1
resource "aws_subnet" "lb1" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.aws_lb1_subnet_cidr}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.primary_az}"
  tags {
    Name = "Terraform_lb1"
  }
}
# Create a second subnet to LB1
resource "aws_subnet" "lb2" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.aws_lb2_subnet_cidr}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.secondary_az}"
  tags {
    Name = "Terraform_lb2"
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "terraform_example_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # Open access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "permissive" {
  name        = "terraform_permissive_sg"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"


  # access from the internet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "sgw_conf" {
  name          = "sgw_config"
  image_id      = "${lookup(var.aws_amis_vsec, var.aws_region)}"
  instance_type = "m4.large" 
  key_name      = "${aws_key_pair.auth.id}"
  security_groups = ["${aws_security_group.permissive.id}"]
  user_data     = "${var.my_user_data}"
  associate_public_ip_address = true
}
resource "aws_launch_configuration" "web_conf" {
  name          = "web_config"
  image_id      = "${lookup(var.aws_amis_web, var.aws_region)}"
  instance_type = "c4.large" 
  key_name      = "${aws_key_pair.auth.id}"
  security_groups = ["${aws_security_group.permissive.id}"]
  user_data     = "${var.ubuntu_user_data}"
}
resource "aws_elb" "sgw" {
  name = "terraform-external-elb"

  subnets         = ["${aws_subnet.external.id}"]
  security_groups = ["${aws_security_group.permissive.id}"]

  listener {
    instance_port     = 8090
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8090/"
    interval            = 5
  }
}

resource "aws_autoscaling_group" "sgw_asg" {
  name = "vsec-layer-autoscale"
  launch_configuration = "${aws_launch_configuration.sgw_conf.id}"
  max_size = 1
  min_size = 1
  load_balancers = ["${aws_elb.sgw.id}"]
  vpc_zone_identifier = ["${aws_subnet.external.id}"]
  tag {
      key = "Name"
      value = "CHKP-AutoScale"
      propagate_at_launch = true
  }
  tag {
      key = "x-chkp-tags"
      value = "management=R80Mgmt:template=Demo-terraform-scale"
      propagate_at_launch = true
  }


}

resource "aws_autoscaling_group" "web_asg" {
  name = "web-layer-autoscale"
  launch_configuration = "${aws_launch_configuration.web_conf.id}"
  max_size = 4
  min_size = 3
  health_check_grace_period = 5
  load_balancers = ["${aws_elb.web.id}"]
  vpc_zone_identifier = ["${aws_subnet.web.id}"]
  tag {
      key = "Name"
      value = "web-AutoScale"
      propagate_at_launch = true
  }
  tag {
      key = "data-profile"
      value = "PCI"
      propagate_at_launch = true
  }
}
resource "aws_elb" "web" {
  name = "terraform-web-elb"

  subnets         = ["${aws_subnet.web.id}"]
  security_groups = ["${aws_security_group.permissive.id}"]
  tags {
    x-chkp-tags = "management=R80Mgmt:template=Demo-terraform-scale"
  }            

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 8090
    lb_protocol       = "http"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

data "aws_route53_zone" "selected" {
  name         = "cloudprotection.eu."
}

resource "aws_route53_record" "iac-demo" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.externaldnshost}.${var.r53zone}"
  type    = "A"
  alias {
    name                   = "${aws_elb.sgw.dns_name}"
    zone_id                = "${aws_elb.sgw.zone_id}"
    evaluate_target_health = true
  }
}

