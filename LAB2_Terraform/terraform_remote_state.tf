# data "terraform_remote_state" "core" {
#   backend = "local"
#   config = {
#     path = "./terraform.tfstate"
#   }
# }
# data "aws_ssm_parameter" "al2023_ami" {
#   name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
# }
# moved {
#   from = aws_security_group.arc_bonus_a_vpce_sg01
#   to   = aws_security_group.arcanum_vpce_sg01
# }