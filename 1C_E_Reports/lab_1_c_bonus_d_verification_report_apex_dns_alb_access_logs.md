# Lab 1C – Bonus D Verification Report

**Module:** Bonus D – Zone Apex ALIAS & ALB Access Logging  
**Project:** Arcanum (Lab 1C)  
**Author:** Ahmad K. Qadafi

---

## 1. Purpose of Bonus D

Bonus D completes two production‑critical concerns that are often skipped in student deployments:

1. **Apex DNS routing** – the naked domain (`arcanum-base.click`) resolves correctly without requiring a subdomain.
2. **Ingress forensics** – Application Load Balancer (ALB) access logs are persisted to S3 for audit, troubleshooting, and incident response.

This module proves the stack is not just reachable, but **observable**.

---

## 2. Final Design Summary

**Traffic & Logging Flow**

User → Route53 (Apex ALIAS) → ALB → Private EC2
                              ↓
                           S3 Logs

**Key decisions:**
- Route53 **ALIAS record** at zone apex (no CNAME allowed at apex)
- ALB **access logs enabled** and delivered to S3
- Bucket policy allows AWS ELB service to write logs
- Logs stored under a deterministic prefix for querying

---

## 3. Authoritative Identifiers

```text
Domain (apex): arcanum-base.click
Hosted Zone ID: Z001663926IWG5SDJP0E3
ALB ARN: arn:aws:elasticloadbalancing:us-east-1:233781468925:loadbalancer/app/arcanum-alb01/828dc9c10c4591fd
ALB DNS Name: arcanum-alb01-1621613657.us-east-1.elb.amazonaws.com
ALB Logs Bucket: arcanum-alb-logs-233781468925
Logs Prefix: alb-access-logs
Region: us-east-1
```

---

## 4. Verification Steps (CLI Evidence)

### 4.1 Verify Apex DNS ALIAS Record Exists

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id Z001663926IWG5SDJP0E3 \
  --query "ResourceRecordSets[?Name=='arcanum-base.click.' && Type=='A'].[Name,AliasTarget.DNSName,AliasTarget.HostedZoneId]" \
  --output table
```

**Result:**
```text
arcanum-base.click. | arcanum-alb01-1621613657.us-east-1.elb.amazonaws.com. | Z35SXDOTRQ7X7K
```

**Interpretation:**
- Apex domain resolves via ALIAS
- Target is the ALB

**Status:** ✅ PASS

---

### 4.2 Verify HTTPS Works on Apex Domain

```bash
curl -I https://arcanum-base.click
```

**Result:**
```text
HTTP/1.1 200 OK
Server: Werkzeug/3.1.5 Python/3.9.25
```

**Interpretation:**
- DNS resolution successful
- TLS handshake valid
- Traffic routed through ALB to application

**Status:** ✅ PASS

---

### 4.3 Verify ALB Access Logging Is Enabled

```bash
aws elbv2 describe-load-balancer-attributes \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:233781468925:loadbalancer/app/arcanum-alb01/828dc9c10c4591fd \
  --region us-east-1 \
  --query "Attributes[?Key=='access_logs.s3.enabled' || Key=='access_logs.s3.bucket' || Key=='access_logs.s3.prefix']" \
  --output table
```

**Result:**
```text
access_logs.s3.enabled | true
access_logs.s3.bucket  | arcanum-alb-logs-233781468925
access_logs.s3.prefix  | alb-access-logs
```

**Interpretation:**
- ALB access logging enabled
- Logs delivered to correct bucket and prefix

**Status:** ✅ PASS

---

### 4.4 Generate Traffic for Log Validation

```bash
curl -I https://arcanum-base.click
curl -I https://app.arcanum-base.click
```

**Interpretation:**
- Requests generate ALB access log entries

---

### 4.5 Verify Logs Arrive in S3

```bash
aws s3 ls s3://arcanum-alb-logs-233781468925/alb-access-logs/AWSLogs/233781468925/elasticloadbalancing/ --recursive | head
```

**Result:**
```text
2026-02-04 01:24:52  12489 AWSLogs/233781468925/elasticloadbalancing/us-east-1/...
```

**Interpretation:**
- Log objects successfully written
- End-to-end logging pipeline confirmed

**Status:** ✅ PASS

---

## 5. Issue Encountered & Resolution

### Issue: Logs Not Immediately Visible

**Observed:**
- S3 bucket initially empty after enabling logging

**Root Cause:**
- ALB access logs are **asynchronous** and may take several minutes to appear

**Resolution:**
- Generated traffic
- Waited for delivery window
- Rechecked S3 prefix

**Outcome:** ✅ RESOLVED / EXPECTED BEHAVIOR

---

## 6. Security & Operational Guarantees

| Control | Status |
|------|------|
| Apex DNS Routing | ✅ Enabled |
| HTTPS at Apex | ✅ Valid |
| ALB Access Logs | ✅ Enabled |
| Log Persistence | ✅ S3 |
| Incident Forensics | ✅ Available |

---

## 7. Conclusion

Bonus D ensures the Arcanum stack is **operationally accountable**.

With apex routing and ALB access logs in place, the system now supports:
- Human‑friendly access patterns
- Post‑incident traffic reconstruction
- Security audits and compliance reviews


— **Ahmad K. Qadafi**

