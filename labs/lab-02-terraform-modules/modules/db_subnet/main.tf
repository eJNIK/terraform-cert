resource "aws_db_subnet_group" "this" {
  name       = "${var.owner_tag}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.owner_tag}-db-subnet-group"
  }
}

