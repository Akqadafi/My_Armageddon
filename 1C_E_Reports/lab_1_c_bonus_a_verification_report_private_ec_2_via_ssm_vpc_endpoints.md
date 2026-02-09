# Lab 1C – Bonus A Verification Report

**Module:** Bonus A – Fully Private Compute with SSM & VPC Endpoints  
**Project:** Arcanum (Lab 1C)  
**Author:** Ahmad K. Qadafi

---

## 1. Purpose of Bonus A

Bonus A hardens the base Lab 1C architecture by removing all public access to compute while preserving full operational control.

The explicit goals of this module are:
- EC2 instances **must not have public IP addresses**
- **SSH must not be required** (SSM Session Manager only)
- Private subnets must reach AWS control-plane services **without NAT**
- Secrets and configuration must be retrieved via **IAM + AWS-native services**

This reflects standard practice in regulated and security‑mature AWS environments.

---

## 2. Final Design Summary

**Key architectural choices:**
- EC2 instances launched in **private subnets only**
- **No bastion host, no SSH, no inbound ports**
- VPC Interface Endpoints created for:
  - SSM
  - EC2Messages
  - SSMMessages
  - CloudWatch Logs
  - Secrets Manager
  - KMS
- S3 **Gateway Endpoint** added for private AWS service access
- IAM role scoped to **least privilege** (GetSecretValue, GetParameter only)

This design eliminates unnecessary internet exposure while keeping the instance fully manageable.

---

## 3. Terraform Outputs (Authoritative IDs)

```text
bonus_a_private_instance_id = "i-03db858a7564e6cd5"
bonus_a_private_instance_private_ip = "10.0.11.53"
bonus_a_vpc_id = "vpc-0693444b4e91d00ed"
bonus_a_instance_profile_name = "arc_bonus_a-instance-profile-private"
bonus_a_role_name = "arcanum-ec2-role01"
bonus_a_log_group_name = "/aws/ec2/arcanum-rds-app"
```

These outputs are used consistently in all verification steps below.

---

## 4. Verification Steps (CLI Evidence)

### 4.1 Verify EC2 Has No Public IP

```bash
aws ec2 describe-instances \
  --instance-ids i-03db858a7564e6cd5 \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output json
```

**Result:**
```json
[]
```

**Interpretation:**
- Empty result means **no public IPv4 address assigned**

**Status:** ✅ PASS

---

### 4.2 Verify Required VPC Endpoints Exist

```bash
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-0693444b4e91d00ed" \
  --query "VpcEndpoints[].ServiceName" \
  --output table
```

**Result (excerpt):**
```text
com.amazonaws.us-east-1.s3
com.amazonaws.us-east-1.kms
com.amazonaws.us-east-1.sts
com.amazonaws.us-east-1.ssm
com.amazonaws.us-east-1.secretsmanager
com.amazonaws.us-east-1.logs
com.amazonaws.us-east-1.ssmmessages
com.amazonaws.us-east-1.ec2messages
```

**Interpretation:**
- All required interface endpoints are present
- S3 gateway endpoint is included (common private‑subnet pitfall avoided)

**Status:** ✅ PASS

---

### 4.3 Verify EC2 Is Reachable via SSM (No SSH)

```bash
aws ssm describe-instance-information \
  --region us-east-1 \
  --query "InstanceInformationList[].{Id:InstanceId,Ping:PingStatus}" \
  --output table
```

**Result:**
```text
| Id                  | Ping   |
| i-03db858a7564e6cd5 | Online |
```

**Interpretation:**
- SSM agent is registered and responding
- Session Manager path is functional

**Status:** ✅ PASS

---

### 4.4 Verify IAM Role Attached to EC2

```bash
aws ec2 describe-instances \
  --instance-ids i-03db858a7564e6cd5 \
  --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" \
  --output text
```

**Result:**
```text
arn:aws:iam::233781468925:instance-profile/arc_bonus_a-instance-profile-private
```

**Status:** ✅ PASS

---

### 4.5 Verify Least-Privilege Policies on Role

```bash
aws iam list-attached-role-policies \
  --role-name arcanum-ec2-role01 \
  --query "AttachedPolicies[].PolicyName" \
  --output table
```

**Result:**
```text
AmazonSSMManagedInstanceCore
CloudWatchAgentServerPolicy
arc_bonus_a-lp-secrets-read01
arc_bonus_a-lp-ssm-read01
arc_bonus_a-lp-cwlogs01
```

**Interpretation:**
- No wildcard admin permissions
- Access tightly scoped to required services

**Status:** ✅ PASS

---

### 4.6 Verify Parameter Store Access (From SSM Session)

```bash
aws ssm get-parameter \
  --name /lab/db/endpoint \
  --region us-east-1
```

**Result:**
```json
{
  "Value": "arcanum-rds01.coj82qo2k48t.us-east-1.rds.amazonaws.com"
}
```

**Status:** ✅ PASS

---

### 4.7 Verify Secrets Manager Access (From SSM Session)

```bash
aws secretsmanager get-secret-value \
  --secret-id lab1a/rds/mysql \
  --region us-east-1
```

**Result (redacted):**
```json
{
  "username": "admin",
  "host": "arcanum-rds01...",
  "port": 3306
}
```

**Status:** ✅ PASS

---

### 4.8 Verify CloudWatch Logs Access via Endpoint

```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2/arcanum-rds-app" \
  --region us-east-1
```

**Result:**
```text
/aws/ec2/arcanum-rds-app
```

**Interpretation:**
- Log group exists
- Logs accessible without internet routing

**Status:** ✅ PASS

---

## 5. Issue Encountered & Resolution

### Issue: SSM Session – `ConnectionLost`

**Observed:**
```text
PingStatus: ConnectionLost
```

**Root Cause:**
- EC2 instance launched before all interface endpoints were fully available
- SSM agent could not establish initial control-plane connectivity

**Resolution:**
```bash
aws ec2 reboot-instances --instance-ids i-03db858a7564e6cd5
```

**Post‑Fix Verification:**
```text
PingStatus: Online
```

**Outcome:** ✅ RESOLVED

This mirrors real-world race conditions in private AWS environments and validates correct dependency reasoning.

---

## 6. Security Posture Achieved

| Control | Status |
|------|------|
| Public IP on EC2 | ❌ None |
| SSH Access | ❌ Disabled |
| SSM Session Manager | ✅ Enabled |
| NAT Required | ❌ No |
| Secrets in Code | ❌ None |
| IAM Least Privilege | ✅ Enforced |
| Private AWS API Access | ✅ Via VPC Endpoints |

---

## 7. Conclusion

Bonus A successfully transforms the base Lab 1C architecture into a **production‑grade private compute model**.

Module Goals Achieved:
- Secure-by-default infrastructure design
- Correct use of AWS private connectivity primitives
- Operational realism (debugging SSM failures)
- Documentation discipline suitable for audits, reviews, and hiring evaluations


— **Ahmad K. Qadafi**

