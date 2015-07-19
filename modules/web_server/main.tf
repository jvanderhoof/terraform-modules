#
# Web Server
#

variable "vpc_id" {}
variable "ami" {}
variable "ssh_key" {}
variable "subnet" {}
variable "name" {}
variable "environment" {}
variable "roles" {}
variable "project" {}

variable "instance_type" {
  default = "m3.medium"
}

variable "instance_count" {
  default = "1"
}

variable "node_security_group" {
  default = "node_traffic"
}

resource "aws_security_group" "web_traffic" {
  name = "web_traffic"
  vpc_id = "${var.vpc_id}"
  description = "Allow all inbound traffic to port 80"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh_traffic" {
  name = "ssh_traffic"
  vpc_id = "${var.vpc_id}"
  description = "Allow all inbound traffic to port 22"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "node_traffic" {
  name = "${var.node_security_group}"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.web_traffic.id}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "web" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.ssh_key}"
  subnet_id = "${var.subnet}"
  count = "${var.instance_count}"

  vpc_security_group_ids = [
    "${aws_security_group.ssh_traffic.id}",
    "${aws_security_group.node_traffic.id}"
  ]

  tags {
    Name = "${var.name} Web ${count.index+1} ${var.environment}"
    Project = "${var.project}"
    Roles = "${var.roles}"
    Stage = "${var.environment}"
  }
}

resource "aws_elb" "elb" {
  name = "${var.project}-${var.environment}"
  subnets = ["${var.subnet}"]
  count = 1

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/up"
    interval = 15
  }

  instances = ["${aws_instance.web.*.id}"]
  security_groups = [ "${aws_security_group.web_traffic.id}" ]

}


output "elb_hostname" {
  value = "${aws_elb.elb.dns_name}"
}

output "node_security_group_id" {
  value = "${aws_security_group.node_traffic.id}"
}
