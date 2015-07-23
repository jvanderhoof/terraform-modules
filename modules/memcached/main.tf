variable "cluster_name" {}
variable "security_group_ids" {}
variable "subnet_ids" {}
variable "vpc_id" {}

variable "node_type" { default = "cache.m1.small" }
variable "port" { default = "11211" }
variable "count" { default = "1" }


resource "aws_elasticache_subnet_group" "memcached-subnet-group" {
  name = "${var.cluster_name}-memcached-subnet-group"
  description = "${var.cluster_name} memcached subnet group"
  subnet_ids = ["${split(",", "${var.subnet_ids}")}"]
}

resource "aws_security_group" "memcached-traffic" {
  name = "${var.cluster_name}-traffic"
  vpc_id = "${var.vpc_id}"
  description = "Memcached cluster security group"
  ingress {
    from_port = "${var.port}"
    to_port = "${var.port}"
    protocol = "tcp"
    security_groups = ["${split(",", "${var.security_group_ids}")}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_cluster" "memcached-server" {
  depends_on = ["aws_elasticache_subnet_group.memcached-subnet-group"]
  cluster_id = "${var.cluster_name}"
  engine = "memcached"
  engine_version = "1.4.5"
  node_type = "${var.node_type}"
  port = "${var.port}"
  num_cache_nodes = "${var.count}"
  parameter_group_name = "default.memcached1.4"
  subnet_group_name = "${var.cluster_name}-memcached-subnet-group"
  apply_immediately = true
  security_group_ids = ["${aws_security_group.memcached-traffic.id}"]
}

output "memcached_urls" {
  value = "${join(",", aws_elasticache_cluster.memcached-server.cache_nodes.*.address)}"
}
output "redis_port" {
  value = "${var.port}"
}
