# Lab 1C – Bonus B Verification Report

**Module:** Bonus B – Public Ingress with ALB, TLS, WAF, and Monitoring  
**Project:** Arcanum (Lab 1C)  
**Author:** Ahmad K. Qadafi

---

## 1. Purpose of Bonus B

Bonus B introduces a **production-grade ingress layer** in front of private compute. The goal is to expose the application securely to the public internet while preserving isolation of EC2 instances.

This module validates that I can:
- Deploy an **internet-facing ALB**
- Terminate **TLS using ACM**
- Attach **AWS WAF** for Layer 7 protection
- Monitor availability via **CloudWatch dashboards and alarms**

This is the canonical AWS pattern used by real SaaS and internal enterprise platforms.

---

## 2. Final Architecture (Bonus B Scope)

**Flow:**

User → ALB (HTTPS) → Private EC2 → RDS

**Security & Observability Controls:**
- TLS termination at ALB (ACM-managed cert)
- HTTP → HTTPS redirect
- WAF attached to ALB (regional scope)
- CloudWatch dashboard for ALB + target health
- SNS-backed CloudWatch alarm on ALB 5xx errors

---

## 3. Terraform Outputs (Authoritative References)

```text
alb_name = "arcanum-alb01"
target_group_name = "arcanum-tg01"
waf_name = "arcanum-waf01"
alarm_name = "arcanum-alb-5xx-alarm01"
dashboard_name = "arcanum-dashboard01"
```

---

## 4. Verification Steps (CLI Evidence)

### 4.1 Verify ALB Exists and Is Active

```bash
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --names arcanum-alb01 \
  --query "LoadBalancers[0].State.Code" \
  --output text
```

**Result:**
```text
active
```

**Status:** ✅ PASS

---

### 4.2 Verify ALB Listeners (HTTP + HTTPS)

```bash
aws elbv2 describe-listeners \
  --region us-east-1 \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:233781468925:loadbalancer/app/arcanum-alb01/828dc9c10c4591fd \
  --query "Listeners[].{Port:Port,Protocol:Protocol}" \
  --output table
```

**Result:**
```text
Port | Protocol
443  | HTTPS
80   | HTTP
```

**Interpretation:**
- HTTPS listener active on 443
- HTTP listener redirects traffic

**Status:** ✅ PASS

---

### 4.3 Verify Target Group Health

```bash
aws elbv2 describe-target-health \
  --region us-east-1 \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:233781468925:targetgroup/arcanum-tg01/29be6b9602567d9c \
  --query "TargetHealthDescriptions[].{Target:Target.Id,State:TargetHealth.State,Reason:TargetHealth.Reason}" \
  --output table
```

**Result:**
```text
Target               | State   | Reason
--------------------|---------|--------
i-0b92ef6cc81a49c4d | healthy | None
```

**Status:** ✅ PASS

---

### 4.4 Verify Target Group Health Check Configuration

```bash
aws elbv2 describe-target-groups \
  --region us-east-1 \
  --target-group-arns arn:aws:elasticloadbalancing:us-east-1:233781468925:targetgroup/arcanum-tg01/29be6b9602567d9c \
  --query "TargetGroups[0].{Protocol:Protocol,Port:Port,HealthPath:HealthCheckPath,Matcher:Matcher.HttpCode}" \
  --output table
```

**Result:**
```text
Protocol | Port | HealthPath | Matcher
HTTP     | 80   | /          | 200-399
```

**Status:** ✅ PASS

---

### 4.5 Verify WAF Is Attached to ALB

```bash
aws wafv2 get-web-acl-for-resource \
  --region us-east-1 \
  --resource-arn arn:aws:elasticloadbalancing:us-east-1:233781468925:loadbalancer/app/arcanum-alb01/828dc9c10c4591fd \
  --query "{Name:WebACL.Name,Arn:WebACL.ARN}" \
  --output table
```

**Result:**
```text
Name          | Arn
arcanum-waf01 | arn:aws:wafv2:us-east-1:233781468925:regional/webacl/arcanum-waf01/...
```

**Status:** ✅ PASS

---

### 4.6 Verify CloudWatch Alarm Exists (ALB 5xx)

```bash
aws cloudwatch describe-alarms \
  --region us-east-1 \
  --alarm-name-prefix "arcanum-alb-5xx" \
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Metric:MetricName}" \
  --output table
```

**Result:**
```text
Name                    | State              | Metric
arcanum-alb-5xx-alarm01 | INSUFFICIENT_DATA  | HTTPCode_ELB_5XX_Count
```

**Interpretation:**
- Alarm exists and is correctly scoped
- Insufficient data is expected during idle testing

**Status:** ✅ PASS

---

### 4.7 Verify CloudWatch Dashboard Exists

```bash
aws cloudwatch list-dashboards \
  --region us-east-1 \
  --dashboard-name-prefix "arcanum" \
  --query "DashboardEntries[].{Name:DashboardName,LastModified:LastModified}" \
  --output table
```

**Result:**
```text
Name                | LastModified
arcanum-dashboard01 | 2026-01-31T01:08:53+00:00
```

**Status:** ✅ PASS

---

## 5. Issues Encountered & Resolution

### Issue: Target Marked Unhealthy

**Observed:**
```text
State: unhealthy
Reason: Target.FailedHealthChecks
```

**Root Cause:**
- Application was not listening on the same port/path as the target group health check

**Resolution:**
- Aligned application listener to port 80
- Ensured `/` endpoint returns HTTP 200

**Post-Fix Verification:**
```text
State: healthy
```

**Outcome:** ✅ RESOLVED

---

## 6. Security Posture Achieved

| Control | Status |
|------|------|
| Public EC2 Access | ❌ None |
| TLS at Ingress | ✅ Enabled |
| WAF Protection | ✅ Attached |
| Health Checks | ✅ Enforced |
| 5xx Alerting | ✅ Enabled |
| Observability | ✅ Dashboard + Metrics |

---

## 7. Conclusion

Bonus B successfully implements a **real-world AWS ingress pattern**:

- Managed TLS
- Layer 7 protection
- Isolated private compute
- Actionable monitoring

This module demonstrates readiness to design, deploy, and **verify** secure internet-facing services in AWS.

— **Ahmad K. Qadafi**

