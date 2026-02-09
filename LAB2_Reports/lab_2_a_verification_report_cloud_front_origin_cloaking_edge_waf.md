# Lab 2A – Verification Report

**Module:** Lab 2A – CloudFront as Sole Public Ingress (Origin Cloaking)  
**Project:** Arcanum  
**Author:** Ahmad K. Qadafi

---

## 1. Purpose of Lab 2A

Lab 2A transitions the Arcanum architecture from **direct ALB ingress** (Lab 1C) to a **CloudFront‑fronted, origin‑cloaked design**.

The intent is to model how real production systems are deployed:
- Only the CDN (CloudFront) is publicly reachable
- The ALB is technically internet‑facing but **functionally private**
- WAF enforcement moves to the **edge**, not the origin
- DNS points to CloudFront, not to the ALB

This lab validates that I can implement *defense‑in‑depth*, not just connectivity.

---

## 2. Final Architecture Summary

**Traffic Flow**

Internet → CloudFront (+ WAF) → ALB (cloaked) → Private EC2 → RDS

**Key security guarantees:**
- Direct ALB access is blocked
- Only CloudFront IP ranges may reach the ALB
- ALB requires a **secret custom header** to forward traffic
- WAF executes at CloudFront (global scope)

---

## 3. Authoritative Terraform Outputs

```text
CloudFront Distribution ID: <redacted>
CloudFront Domain: dxxxxxxxxxxxxx.cloudfront.net
ALB DNS Name: arcanum-alb01-1621613657.us-east-1.elb.amazonaws.com
Origin Header Name: X-arcanum-base
Origin Header Value: <sensitive>
Route53 Zone: arcanum-base.click
```

---

## 4. Verification Requirements (From Lab Instructions)

Lab 2A requires proof of **three conditions**:

1. The ALB is **not directly reachable**
2. WAF is attached to **CloudFront**, not the ALB
3. DNS resolves to **CloudFront**, not ALB

Each condition is verified below with CLI evidence.

---

## 5. Verification Steps (CLI Evidence)

### 5.1 Verify Direct ALB Access Is Blocked

```bash
curl -I https://arcanum-alb01-1621613657.us-east-1.elb.amazonaws.com
```

**Result:**
```text
HTTP/1.1 403 Forbidden
```

**Interpretation:**
- Request reaches the ALB
- Missing required origin header
- Listener rule correctly blocks traffic

**Status:** ✅ PASS

---

### 5.2 Verify CloudFront Access Succeeds

```bash
curl -I https://arcanum-base.click
curl -I https://app.arcanum-base.click
```

**Result:**
```text
HTTP/2 200
```

**Interpretation:**
- Requests routed through CloudFront
- Custom origin header injected
- ALB forwards traffic to target group

**Status:** ✅ PASS

---

### 5.3 Verify WAF Scope Is CLOUDFRONT

```bash
aws wafv2 get-web-acl \
  --name arcanum-cf-waf01 \
  --scope CLOUDFRONT \
  --region us-east-1
```

**Result (excerpt):**
```json
{
  "Scope": "CLOUDFRONT",
  "DefaultAction": { "Allow": {} }
}
```

**Status:** ✅ PASS

---

### 5.4 Verify CloudFront Distribution References WAF

```bash
aws cloudfront get-distribution \
  --id <DISTRIBUTION_ID> \
  --query "Distribution.DistributionConfig.WebACLId"
```

**Result:**
```text
arn:aws:wafv2::233781468925:global/webacl/arcanum-cf-waf01/...
```

**Status:** ✅ PASS

---

### 5.5 Verify DNS Resolves to CloudFront (Not ALB)

```bash
dig arcanum-base.click A +short
dig app.arcanum-base.click A +short
```

**Result:**
```text
13.224.xxx.xxx
13.249.xxx.xxx
```

**Interpretation:**
- Anycast IPs owned by CloudFront
- No ALB IPs returned

**Status:** ✅ PASS

---

## 6. Security Controls Implemented

| Control | Purpose | Status |
|------|------|------|
| CloudFront Prefix List SG Rule | Restrict ALB ingress | ✅ |
| Custom Origin Header | Prevent header spoofing | ✅ |
| ALB Listener Rule | Enforce header match | ✅ |
| Edge WAF (Global) | Block attacks early | ✅ |
| DNS → CloudFront | Hide origin | ✅ |

---

## 7. Issues Encountered & Resolution

### Issue: CloudFront Access Initially Returned 403

**Root Cause:**
- Origin header value mismatch between CloudFront and ALB listener rule

**Resolution:**
- Normalized header value using Terraform variable
- Re‑deployed CloudFront distribution and ALB listener rule

**Outcome:** ✅ RESOLVED

---

## 8. Conclusion

Lab 2A successfully converts the Arcanum stack into a **CDN‑fronted, origin‑cloaked architecture**.

Goals Achieved:
- The ALB is invisible to the public internet
- All traffic is inspected at the edge
- DNS reveals nothing about the origin
- Security controls are layered, not singular


— **Ahmad K. Qadafi**

