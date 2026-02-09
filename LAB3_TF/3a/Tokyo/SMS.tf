###########################################
# Secrets Manager (DB Credentials)
############################################

# Explanation: Secrets Manager is shibuya’s locked holster—credentials go here, not in code.
#Recovery_window_in_days forces deletion of secrets and allows re-deployment of secret without constantly changing name

resource "aws_secretsmanager_secret" "shibuya_db_secret01" {
  name                    = "lab3a/rds/mysql"
  recovery_window_in_days = 0
}

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "shibuya_db_secret_version01" {
  secret_id = aws_secretsmanager_secret.shibuya_db_secret01.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.shibuya_rds01.address
    port     = aws_db_instance.shibuya_rds01.port
    dbname   = var.db_name
  })
}