# enable_https                  = true
# certificate_validation_method = "DNS"

my_ip_cidr = "4.4.151.30/32"

manage_route53_in_terraform = false
route53_hosted_zone_id      = "Z001663926IWG5SDJP0E3"


enable_origin_cloaking  = true
cloudfront_acm_cert_arn = "arn:aws:acm:us-east-1:233781468925:certificate/c0dfeb44-b489-42c4-96d0-4b2b8fe26461"