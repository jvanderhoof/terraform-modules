variable "cluster_name" {}
variable "security_group_ids" {}
variable "subnet" {}
variable "vpc_id" {}

variable "node_type" {
  default = "cache.m1.small"
}

resource "aws_security_group" "redis-traffic" {
  name = "${var.cluster_name}-traffic"
  vpc_id = "${var.vpc_id}"
  description = "Redis cluster security group"
  ingress {
    from_port = 6379
    to_port = 6379
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


resource "aws_elasticache_cluster" "redis-server" {
  cluster_id = "${var.cluster_name}"
  engine = "redis"
  engine_version = "2.8.19"
  node_type = "${var.node_type}"
  port = 6379
  num_cache_nodes = 1
  parameter_group_name = "default.redis2.8"
  subnet_group_name = "${var.subnet}"
  apply_immediately = true
  security_group_ids = ["${aws_security_group.redis-traffic.id}"]
}

output "redis_url" {
  value = "${aws_elasticache_cluster.redis-server.cache_nodes.0.address}"
}
output "redis_port" {
  value = "${aws_elasticache_cluster.redis-server.cache_nodes.0.port}"
}
