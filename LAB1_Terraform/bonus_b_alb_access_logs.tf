# ############################################
# # Bonus B - ALB Access Logs (S3)
# # Resource names MATCH your state list:
# #   aws_s3_bucket.arcanum_alb_logs01[0]
# #   aws_s3_bucket_policy.arcanum_alb_logs_policy01[0]
# #   aws_s3_bucket_public_access_block.arcanum_alb_logs_pab01[0]
# #   aws_s3_bucket_ownership_controls.arcanum_alb_logs_owner01[0]
# ############################################

# data "aws_caller_identity" "current" {}

# # Optional: let user override bucket name, otherwise build a predictable one
# locals {
#   alb_logs_bucket_name = coalesce(
#     var.alb_logs_bucket_name,
#     "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"
#   )
# }

# resource "aws_s3_bucket" "arcanum_alb_logs01" {
#   count         = var.enable_alb_access_logs ? 1 : 0
#   bucket        = local.alb_logs_bucket_name
#   force_destroy = true
# }

# resource "aws_s3_bucket_ownership_controls" "arcanum_alb_logs_owner01" {
#   count  = var.enable_alb_access_logs ? 1 : 0
#   bucket = aws_s3_bucket.arcanum_alb_logs01[0].id

#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "arcanum_alb_logs_pab01" {
#   count  = var.enable_alb_access_logs ? 1 : 0
#   bucket = aws_s3_bucket.arcanum_alb_logs01[0].id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # ALB log delivery policy (modern service principal)
# resource "aws_s3_bucket_policy" "arcanum_alb_logs_policy01" {
#   count  = var.enable_alb_access_logs ? 1 : 0
#   bucket = aws_s3_bucket.arcanum_alb_logs01[0].id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid      = "AWSLogDeliveryWrite"
#         Effect   = "Allow"
#         Principal = {
#           Service = "logdelivery.elb.amazonaws.com"
#         }
#         Action   = "s3:PutObject"
#         Resource = "${aws_s3_bucket.arcanum_alb_logs01[0].arn}/${var.alb_access_logs_prefix}/*"
#       },
#       {
#         Sid      = "AWSLogDeliveryAclCheck"
#         Effect   = "Allow"
#         Principal = {
#           Service = "logdelivery.elb.amazonaws.com"
#         }
#         Action   = "s3:GetBucketAcl"
#         Resource = aws_s3_bucket.arcanum_alb_logs01[0].arn
#       }
#     ]
#   })
# }
