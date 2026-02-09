# Lab 1C – Bonus E Verification Report

**Module:** Bonus E – AWS WAF Logging & Security Telemetry  
**Project:** Arcanum (Lab 1C)  
**Author:** Ahmad K. Qadafi

---

## 1. Purpose of Bonus E

Bonus E completes the **security observability layer** of the Arcanum stack.

Where earlier modules established ingress (ALB), protection (WAF), and availability (alarms), this module ensures that **WAF decisions are logged, queryable, and attributable**.

The objective is to prove that:
- WAF logging is explicitly enabled (not assumed)
- Exactly **one valid logging destination** is configured
- Logs are actually being written
- Security events can be inspected and correlated with ALB behavior

This is what separates *having a firewall* from *being able to investigate incidents*.

---

## 2. Final Design Summary

**Chosen logging destination:** CloudWatch Logs  
(Selected for fast search, low friction, and immediate visibility during incident response.)

**Flow:**

Client Request → ALB → WAF → ALLOW / BLOCK
                               ↓
                        CloudWatch Logs

**Key design decisions:**
- Use `aws_wafv2_web_acl_logging_configuration`
- Log group name **must start with `aws-waf-logs-`** (AWS requirement)
- One destination per Web ACL (AWS constraint)
- Sensitive headers (e.g., `authorization`, `cookie`) redacted

---

## 3. Authoritative Identifiers

```text
Web ACL ARN:
arn:aws:wafv2:us-east-1:233781468925:regional/webacl/arcanum-waf01/acc2b12d-670d-43b2-9d15-b3d2375bc008

WAF Log Group:
aws-waf-logs-arcanum-webacl01

Region:
us-east-1
```

---

## 4. Verification Steps (CLI Evidence)

### 4.1 Verify WAF Logging Configuration Exists

```bash
aws wafv2 get-logging-configuration \
  --region us-east-1 \
  --resource-arn arn:aws:wafv2:us-east-1:233781468925:regional/webacl/arcanum-waf01/acc2b12d-670d-43b2-9d15-b3d2375bc008
```

**Result:**
```json
{
  "LoggingConfiguration": {
    "LogDestinationConfigs": [
      "arn:aws:logs:us-east-1:233781468925:log-group:aws-waf-logs-arcanum-webacl01"
    ],
    "LogType": "WAF_LOGS"
  }
}
```

**Interpretation:**
- Logging explicitly enabled
- Exactly one destination configured

**Status:** ✅ PASS

---

### 4.2 Generate Traffic Through WAF

```bash
curl -I https://arcanum-base.click/
curl -I https://app.arcanum-base.click/
```

**Interpretation:**
- Requests traverse ALB and WAF
- Events should appear in WAF logs

---

### 4.3 Verify Log Streams Are Created

```bash
aws logs describe-log-streams \
  --region us-east-1 \
  --log-group-name aws-waf-logs-arcanum-webacl01 \
  --order-by LastEventTime \
  --descending \
  --max-items 5
```

**Result (excerpt):**
```json
{
  "logStreamName": "us-east-1_arcanum-waf01_0",
  "lastEventTimestamp": 1770167181305
}
```

**Status:** ✅ PASS

---

### 4.4 Inspect Recent WAF Log Events

```bash
aws logs filter-log-events \
  --region us-east-1 \
  --log-group-name aws-waf-logs-arcanum-webacl01 \
  --max-items 5
```

**Result (excerpt, redacted):**
```json
{
  "action": "ALLOW",
  "httpRequest": {
    "clientIp": "103.38.81.27",
    "country": "HK",
    "uri": "/admin",
    "httpMethod": "POST",
    "host": "arcanum-base.click"
  }
}
```

**Interpretation:**
- WAF decision recorded
- Source IP, country, method, and path visible
- Sensitive headers redacted

**Status:** ✅ PASS

---

## 5. Issue Encountered & Resolution

### Issue: Logs Not Immediately Visible

**Observed:**
- No log streams immediately after enabling logging

**Root Cause:**
- WAF logs are emitted **only after traffic occurs**

**Resolution:**
- Generated traffic through ALB endpoints
- Re-queried log group

**Outcome:** ✅ EXPECTED BEHAVIOR / RESOLVED

---

## 6. Security & Incident Response Value

With WAF logging enabled, the system can now answer:

- Are spikes in 5xx errors caused by attacks or backend failures?
- Which IPs, ASNs, or countries are generating suspicious traffic?
- Which paths are being probed (e.g., `/admin`, `/index.php`)?
- Did WAF rules mitigate the traffic or allow it downstream?

This closes the **security feedback loop**:

ALB Metrics → WAF Decisions → Access Logs → Alarms

---

## 7. Conclusion

Bonus E completes the Arcanum ingress stack as a **forensically observable system**.

At this point, the deployment supports:
- Secure ingress (TLS)
- Layer 7 protection (WAF)
- Availability monitoring (alarms)
- Traffic forensics (ALB logs)
- **Security decision auditing (WAF logs)**



— **Ahmad K. Qadafi**

