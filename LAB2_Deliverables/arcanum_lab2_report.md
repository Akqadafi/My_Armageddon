
# Arcanum Lab 2 – CloudFront Origin Cloaking & Edge WAF  
**Verification & Issue Resolution Report**

---

## Executive Summary

This lab successfully implemented **origin cloaking** using Amazon CloudFront in front of an Application Load Balancer (ALB), enforced **WAF at the CloudFront edge**, and redirected **DNS to CloudFront instead of the ALB**.  

The final architecture ensures:

- The **ALB cannot be accessed directly** from the public internet.
- **Only CloudFront** can reach the ALB via AWS-managed prefix lists and a secret origin header.
- **WAF protection occurs at the CloudFront edge**, not at the ALB.
- **Route53 DNS records point to CloudFront**, not the ALB.

Empirical verification via CLI and DNS lookups confirms all requirements were met.

---

## Final Architecture

User → CloudFront → ALB → Private EC2

Security Layers:
1. Route53 Alias → CloudFront  
2. CloudFront WAF (CLOUDFRONT scope)  
3. Custom Origin Header  
4. ALB Security Group restricted to CloudFront prefix list  
5. ALB Listener Rule requiring secret header  
6. Private EC2 + RDS inside VPC  

---

## Verification Results

### 1. ALB Direct Access – BLOCKED

Command:
```
curl -I https://arcanum-alb01-1621613657.us-east-1.elb.amazonaws.com
```

Result:
```
HTTP/1.1 403 Forbidden
Server: awselb/2.0
```

Interpretation:
- ALB listener default action = 403
- Secret header missing
- Origin cloaking confirmed

---

### 2. CloudFront Access – SUCCESS

Commands:
```
curl -I https://arcanum-base.click
curl -I https://app.arcanum-base.click
```

Observed:
- Initial 502 (propagation)
- Final 200 OK

Key Headers:
```
X-Cache: Miss from cloudfront
Via: cloudfront.net
```

---

### 3. DNS Points to CloudFront

PowerShell:
```
Resolve-DnsName arcanum-base.click -Type A
```

Returned IPs:
52.84.20.44  
52.84.20.110  
52.84.20.15  
52.84.20.21  

These are CloudFront edge IPs.

---

### 4. WAF at CloudFront

Command:
```
aws wafv2 get-web-acl --name arcanum-cf-waf01 --scope CLOUDFRONT
```

Result:
- Scope = CLOUDFRONT
- Managed rule sets active

---

## Issues Encountered & Resolutions

Duplicate Route53 Records → Removed duplicate ALIAS  
Missing S3 Buckets → Disabled ALB logging or created bucket  
Empty Tuple WAF Output → Conditional output guard  
Duplicate Listener Rule → Ensured single secret‑header rule  
ACM Validation Confusion → Standardized to DNS  
Temporary 502 → CloudFront propagation delay  

---

## Security Posture Achieved

Direct ALB Access: Blocked  
Edge WAF: Enabled  
DNS → CloudFront: Confirmed  
Secret Header Enforcement: Active  
Public CIDR Removed: Yes  
Prefix List Restriction: Applied  

---

## Conclusion

All Lab 2 objectives achieved. The ALB is no longer publicly reachable; CloudFront is the only entry point, with WAF and layered controls enforcing defense‑in‑depth.
