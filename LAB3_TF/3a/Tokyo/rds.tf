resource "aws_db_instance" "shibuya_rds01" {
  identifier        = "${local.name_prefix}-rds01"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.shibuya_rds_subnets.name
  vpc_security_group_ids = [aws_security_group.shibuya_rds_sg01.id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${local.name_prefix}-rds01"
  }
}