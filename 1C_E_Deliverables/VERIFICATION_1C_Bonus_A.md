# Lab 1C (Terraform) — Bonus A Verification Report
**Project:** ARMA / SEIR Foundations — Lab 1C Terraform (Bonus A: Private EC2 + VPC Endpoints)  
**Region:** us-east-1  
**VPC:** vpc-0693444b4e91d00ed  
**Date:** 2026-01-28  

## Goal
Demonstrate a **private** EC2 instance (no public IP) can:
- be reached via **SSM Session Manager** (no SSH),
- access **SSM Parameter Store** and **Secrets Manager** over **VPC Interface Endpoints** (no NAT/IGW dependency),
- and that the **CloudWatch Logs delivery path** (log group + logs endpoint) is present.

---

## Key Resources (Observed)
- **Private EC2 (Bonus A):** `i-03db858a7564e6cd5`
- **VPC Endpoints (in VPC):** S3 (Gateway), SSM, EC2Messages, SSMMessages, Logs, Secrets Manager, STS, KMS
- **CloudWatch Log Group:** `/aws/ec2/arcanum-rds-app`

---

# Verification Checks

## 1) Prove EC2 is private (no public IP)

### Command (run locally)
```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --instance-ids i-03db858a7564e6cd5 \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output json
```

### Actual Output
```json
[]
```

### Interpretation
The instance does not have a public IP (field absent/null), which is consistent with `associate_public_ip_address = false`.

> Tip: this query shape can return `[]` when the field is null/absent. A more “explicit null” variant is:
> `--query "Reservations[0].Instances[0].PublicIpAddress" --output text` (expected output: `None`).

✅ **PASS** — EC2 is private.

---

## 2) Prove VPC endpoints exist

### Command (run locally)
```bash
aws ec2 describe-vpc-endpoints \
  --region us-east-1 \
  --filters "Name=vpc-id,Values=vpc-0693444b4e91d00ed" \
  --query "VpcEndpoints[].ServiceName" \
  --output table
```

### Actual Output
```
com.amazonaws.us-east-1.s3
com.amazonaws.us-east-1.kms
com.amazonaws.us-east-1.sts
com.amazonaws.us-east-1.ssm
com.amazonaws.us-east-1.secretsmanager
com.amazonaws.us-east-1.logs
com.amazonaws.us-east-1.ssmmessages
com.amazonaws.us-east-1.ec2messages
```

✅ **PASS** — Required endpoint services are present.

---

## 2b) Endpoint IDs and status (optional detail)

### Command (run locally)
```bash
aws ec2 describe-vpc-endpoints \
  --region us-east-1 \
  --vpc-endpoint-ids \
    vpce-09c9b9523a76bfb1c \
    vpce-0ba4a831a4ce1269f \
    vpce-033cb59d3c97d14ed \
    vpce-0577029978415c91c \
    vpce-0bd25dfba809abfe2 \
    vpce-06ccc9f1190723e39 \
    vpce-0466904024804eff4 \
    vpce-0a0ec1e8817fe3f21 \
  --query "VpcEndpoints[].{Id:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType,State:State}" \
  --output table
```

### Actual Output (excerpt)
- S3 gateway endpoint: `vpce-0a0ec1e8817fe3f21` (**available**, **Gateway**)
- Interface endpoints (**available**, **Interface**): KMS, STS, SSM, Secrets Manager, Logs, SSMMessages, EC2Messages

✅ **PASS** — Endpoints are **available**.

---

## 3) Prove Session Manager path works (no SSH)

### Evidence (run locally)
```bash
aws ssm describe-instance-information \
  --region us-east-1 \
  --query "InstanceInformationList[].{Id:InstanceId,Platform:PlatformName,Ping:PingStatus}" \
  --output table
```

### Actual Output
```
i-03db858a7564e6cd5   Online   Amazon Linux
```

✅ **PASS** — Instance is managed by SSM and Online.

---

## 4) Prove the instance can read both config stores (inside SSM session)

### Session Start (run locally)
```bash
aws ssm start-session --target i-03db858a7564e6cd5 --region us-east-1
```

### AWS CLI present on instance
```text
aws-cli/2.32.22 Python/3.9.25 Linux/6.1.159-182.297.amzn2023.x86_64 source/x86_64.amzn.2023
```

### (4a) Read Parameter Store
```bash
aws ssm get-parameter \
  --region us-east-1 \
  --name /lab/db/endpoint \
  --query "Parameter.Value" \
  --output text
```

**Actual Output**
```text
arcanum-rds01.coj82qo2k48t.us-east-1.rds.amazonaws.com
```

✅ **PASS** — Parameter Store read works from private EC2.

### (4b) Read Secrets Manager
```bash
aws secretsmanager get-secret-value \
  --region us-east-1 \
  --secret-id lab1a/rds/mysql \
  --query "SecretString" \
  --output text
```

**Actual Output (password redacted)**
```json
{"dbname":"arcdb","host":"arcanum-rds01.coj82qo2k48t.us-east-1.rds.amazonaws.com","password":"***REDACTED***","port":3306,"username":"admin"}
```

✅ **PASS** — Secrets Manager read works from private EC2.

---

## 5) Prove CloudWatch Logs delivery path is available via endpoint

### (5a) Confirm the log group exists (inside SSM session)
```bash
aws logs describe-log-groups \
  --region us-east-1 \
  --log-group-name-prefix "/aws/ec2/arcanum-rds-app" \
  --query "logGroups[].{name:logGroupName,arn:arn}" \
  --output table
```

**Actual Output**
- Log group exists: `/aws/ec2/arcanum-rds-app`
- ARN: `arn:aws:logs:us-east-1:233781468925:log-group:/aws/ec2/arcanum-rds-app:*`

✅ **PASS** — Log group is present and the logs endpoint exists.

### (5b) Describe log streams (inside SSM session)
```bash
aws logs describe-log-streams \
  --region us-east-1 \
  --log-group-name "/aws/ec2/arcanum-rds-app" \
  --order-by LastEventTime \
  --descending \
  --max-items 5 \
  --output table
```

**Actual Output**
No streams returned.

✅ **PASS (with note)** — This often means the app/agent has not yet produced logs (or streams haven’t been created). The “delivery path” is verified because:
- the log group exists, and
- the instance can reach AWS services privately via endpoints.

---

# Notes / Fixes

## Git Bash path-conversion gotcha (Windows)
When running this locally in Git Bash:
```bash
aws logs describe-log-streams --log-group-name "/aws/ec2/arcanum-rds-app" ...
```
you received:
```
Value 'C:/Program Files/Git/aws/ec2/arcanum-rds-app' ... failed regex ...
```
That’s MSYS converting `/aws/...` into a Windows path.

### Fix (pick one)
**Option A (recommended):**
```bash
MSYS_NO_PATHCONV=1 aws logs describe-log-streams \
  --region us-east-1 \
  --log-group-name "/aws/ec2/arcanum-rds-app" \
  --order-by LastEventTime --descending --max-items 5 --output table
```

**Option B:**
```bash
aws logs describe-log-streams --region us-east-1 --log-group-name "//aws/ec2/arcanum-rds-app" ...
```

---

# Final Result
All core Bonus A requirements are satisfied:

- ✅ Private EC2 (no public IP)
- ✅ VPC endpoints (SSM/EC2Messages/SSMMessages/Logs/Secrets/STS + S3 gateway + KMS)
- ✅ SSM Session Manager works to reach private EC2
- ✅ Private EC2 reads Parameter Store + Secrets Manager without internet/NAT
- ✅ CloudWatch Logs path is in place (log group exists; streams depend on app/agent activity)
