# Required Variables
variable "instance_name" {}
variable "vpc_id" {}
variable "username" {}
variable "password" {}
variable "availability_zone" {}
variable "subnet_group_name" {}
#variable "" {}

# Default Variables
variable "instance_class" { default = "db.t2.micro" }
variable "cidr_blocks" { default = "" }
variable "additional_security_groups" { default = "" }
variable "allocated_storage" { default = 10 }
variable "engine_version" { default = "9.4.1" }
variable "storage_type" { default = "gp2" }
variable "parameter_group_name" { default = "default.postgres9.4" }
variable "backup_retention_period" { default = "14" }
#variable "" { default = "" }

resource "aws_security_group" "rds" {
  name = "${var.instance_name}_rds_default"
  vpc_id = "${var.vpc_id}"
  description = "RDS default security group - Allow all inbound traffic to port 5432"

  ingress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = ["${split(",", "${var.cidr_blocks}")}"]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "rds" {
  identifier = "${var.instance_name}-rds"
  allocated_storage = "${var.allocated_storage}"
  engine = "postgres"
  engine_version = "${var.engine_version}"
  instance_class = "${var.instance_class}"
  storage_type = "${var.storage_type}"
  name = "${var.instance_name}"
  username = "${var.username}"
  password = "${var.password}"
  publicly_accessible = true
  availability_zone = "${var.availability_zone}"
  db_subnet_group_name = "${var.subnet_group_name}" #"rds-default"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  parameter_group_name = "default.postgres9.4"
}


output "rds_hostname" {
  value = "${aws_db_instance.rds.address}"
}
