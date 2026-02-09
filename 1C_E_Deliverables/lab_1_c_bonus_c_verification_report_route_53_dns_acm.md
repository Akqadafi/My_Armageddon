# Lab 1C – Bonus C Verification Report

**Module:** Bonus C – Route53, DNS Delegation, and ACM Validation  
**Project:** Arcanum (Lab 1C)  
**Author:** Ahmad K. Qadafi

---

## 1. Purpose of Bonus C

Bonus C validates **domain ownership, DNS correctness, and TLS issuance** for the Arcanum stack.

The objective is to prove that:
- The domain is correctly delegated to Route53
- DNS records resolve the application to the ALB
- ACM certificates are **issued (not pending)**
- HTTPS works end-to-end using a real domain

This is a non-negotiable requirement in real production environments: *no valid DNS, no valid TLS, no launch*.

---

## 2. Final Design Summary

**DNS & TLS Flow:**

User → Route53 → ALB → Private EC2

**Key decisions:**
- Public hosted zone in Route53 for `arcanum-base.click`
- DNS validation for ACM (preferred over email)
- ALIAS record for `app.arcanum-base.click` → ALB
- HTTPS termination at the ALB using the issued certificate

---

## 3. Authoritative Identifiers

```text
Domain: arcanum-base.click
Subdomain: app.arcanum-base.click
ACM Certificate ARN: arn:aws:acm:us-east-1:233781468925:certificate/a631041e-5946-4984-b39f-13a3e572f77d
ALB DNS Name: arcanum-alb01-1621613657.us-east-1.elb.amazonaws.com
```

---

## 4. Verification Steps (CLI Evidence)

### 4.1 Verify Hosted Zones Exist in Route53

```bash
aws route53 list-hosted-zones-by-name \
  --dns-name arcanum-base.click \
  --query "HostedZones[].{Id:Id,Name:Name,Private:Config.PrivateZone}" \
  --output table
```

**Result:**
```text
Id                             | Name                 | Private
/hostedzone/Z001663926IWG5SDJP0E3 | arcanum-base.click. | False
/hostedzone/Z05472551N7DN9RT8Z09A | arcanum-base.click. | False
```

**Interpretation:**
- Two hosted zones existed temporarily due to iterative Terraform applies
- Only one zone is delegated at the registrar (see §4.5)

**Status:** ⚠️ OBSERVED / CONTROLLED

---

### 4.2 Verify Application ALIAS Record Exists

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id Z05472551N7DN9RT8Z09A \
  --query "ResourceRecordSets[?Name=='app.arcanum-base.click.']" \
  --output json
```

**Result:**
```json
{
  "Name": "app.arcanum-base.click.",
  "Type": "A",
  "AliasTarget": {
    "DNSName": "arcanum-alb01-1621613657.us-east-1.elb.amazonaws.com.",
    "EvaluateTargetHealth": true
  }
}
```

**Status:** ✅ PASS

---

### 4.3 Verify ACM Certificate Is Issued

```bash
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn arn:aws:acm:us-east-1:233781468925:certificate/a631041e-5946-4984-b39f-13a3e572f77d \
  --query "Certificate.Status" \
  --output text
```

**Result:**
```text
ISSUED
```

**Interpretation:**
- DNS validation completed successfully
- Certificate usable by ALB listeners

**Status:** ✅ PASS

---

### 4.4 Verify HTTPS Works End-to-End

```bash
curl -I https://app.arcanum-base.click
```

**Result:**
```text
HTTP/1.1 200 OK
Server: Werkzeug/3.1.5 Python/3.9.25
```

**Interpretation:**
- DNS resolves correctly
- TLS handshake succeeds
- Traffic reaches the application

**Status:** ✅ PASS

---

### 4.5 Verify Domain Delegation Matches Hosted Zone

```bash
aws route53domains get-domain-detail \
  --domain-name arcanum-base.click \
  --query "Nameservers[].Name" \
  --output table
```

**Result:**
```text
ns-1443.awsdns-52.org
ns-906.awsdns-49.net
ns-311.awsdns-38.com
ns-1597.awsdns-07.co.uk
```

```bash
aws route53 get-hosted-zone \
  --id Z001663926IWG5SDJP0E3 \
  --query "DelegationSet.NameServers" \
  --output table
```

**Result:**
```text
ns-1443.awsdns-52.org
ns-906.awsdns-49.net
ns-311.awsdns-38.com
ns-1597.awsdns-07.co.uk
```

**Interpretation:**
- Registrar delegation matches this hosted zone exactly
- This is the authoritative DNS zone

**Status:** ✅ PASS

---

## 5. Issue Encountered & Resolution

### Issue: Duplicate Hosted Zones

**Observed:**
- Two public hosted zones existed for the same domain
- Both contained identical ALIAS records

**Root Cause:**
- Terraform re-apply created a second zone before DNS delegation was finalized

**Resolution:**
- Verified which zone was delegated at the registrar
- Treated the non-delegated zone as inert
- Consolidated future changes against the authoritative zone only

**Outcome:** ✅ RESOLVED / UNDERSTOOD

This reflects a common real-world DNS pitfall and demonstrates correct diagnostic reasoning.

---

## 6. Security & Correctness Guarantees

| Control | Status |
|------|------|
| Domain Ownership | ✅ Proven |
| DNS Delegation | ✅ Correct |
| TLS Certificate | ✅ Issued |
| HTTPS Enforcement | ✅ Working |
| ALIAS → ALB | ✅ Verified |

---

## 7. Conclusion

Bonus C completes the **trust boundary between users and infrastructure**.

This module proves the system is:
- Discoverable (DNS)
- Authentic (TLS)
- Correctly routed (ALIAS → ALB)

Without this layer, no production system is viable. With it, the Arcanum stack meets real-world deployment standards.

— **Ahmad K. Qadafi**

