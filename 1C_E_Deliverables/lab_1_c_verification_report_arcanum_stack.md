# Lab 1C Verification Report – Arcanum Stack

**Author:** Ahmad K. Qadafi  
**Role Context:** Cloud / DevOps Engineer Candidate  
**Stack:** AWS · Terraform · EC2 · RDS · ALB · WAF · Route53 · IAM · VPC Endpoints

---

## Executive Summary

This document verifies the successful completion of **Lab 1C and all associated Bonus sections (A–E)**. It is written not as a checklist dump, but as a *defensible engineering narrative*: what I built, why I built it that way, how I verified it, what broke, and how I fixed it.

The resulting system represents a **real enterprise cloud pattern**:
- Public, TLS‑secured ingress via ALB
- Private compute and database layers
- No SSH access; SSM‑only operations
- Least‑privilege IAM and secrets handling
- Defense‑in‑depth (WAF, alarms, logging)
- Full CLI‑based verification

This is the same architecture I would expect to encounter—or be asked to reason about—in AWS Solutions Architect, Cloud Security, or DevOps interviews.

---

## Architecture Overview

### High‑Level Design

**Ingress → Compute → Data**, with explicit trust boundaries:

- **Route53 + ACM** provide DNS and TLS
- **Application Load Balancer** terminates HTTPS and forwards traffic
- **Private EC2 instances** run the application
- **Amazon RDS (MySQL)** stores state
- **Secrets Manager + SSM Parameter Store** provide configuration
- **IAM roles** replace static credentials
- **VPC Interface Endpoints** eliminate NAT dependency

The application itself is intentionally simple. The learning objective is *infrastructure correctness, security, and observability*.

---

## Core Lab (1A / 1C): EC2 → RDS Integration

### Objective

Prove that a private EC2 instance can securely:
- Retrieve credentials dynamically
- Connect to a private RDS instance
- Read and write data

### Key Design Decisions

- **RDS is not publicly accessible**
- **Security Group to Security Group rules** instead of CIDRs
- **IAM instance role** for Secrets Manager access
- **No credentials embedded in AMIs or code**

This mirrors how real production systems avoid lateral movement and credential leakage.

### Verification Highlights

- EC2 instance exists and is running
- IAM instance profile attached (non‑null)
- RDS instance available with private endpoint
- RDS SG allows inbound TCP 3306 *only* from EC2 SG
- EC2 can retrieve secrets and parameters via IAM
- Application successfully initializes, inserts, and reads data

Where applicable, all verification was performed via **AWS CLI**, not screenshots.

---

## Bonus A: Fully Private Compute (SSM‑Only)

### Objective

Eliminate public IPs and SSH entirely, while maintaining manageability.

### Implementation

- EC2 instances launched **without public IPs**
- **SSM Session Manager** replaces SSH
- **VPC Interface Endpoints** created for:
  - ssm
  - ec2messages
  - ssmmessages
  - logs
  - secretsmanager
  - kms
- **S3 Gateway Endpoint** added for package access patterns

This reflects modern, regulated‑environment practices.

### Verification

- EC2 has no public IP (null)
- Instance appears in `describe-instance-information`
- SSM session succeeds
- Secrets Manager and Parameter Store readable from instance
- CloudWatch log group exists and is reachable via endpoint

### Issue Encountered & Resolution

**Issue:** SSM session initially showed `ConnectionLost`.

**Root Cause:** The instance had launched before all interface endpoints were fully available.

**Resolution:**
- Verified endpoint state = `available`
- Rebooted the instance
- Confirmed SSM agent heartbeat resumed

This mirrors a real‑world dependency‑ordering issue commonly seen in private environments.

---

## Bonus B: Public Ingress with TLS, WAF, and Monitoring

### Objective

Introduce a production‑grade ingress layer.

### Implementation

- Internet‑facing **ALB**
- **HTTPS listener (443)** using ACM certificate
- HTTP → HTTPS redirect
- **Target group** pointing to private EC2
- **AWS WAF** attached to ALB
- **CloudWatch alarm** on ALB 5xx errors
- **CloudWatch dashboard** for visibility

### Verification

- ALB state = active
- Listeners on ports 80 and 443
- Target health = healthy
- WAF successfully associated with ALB
- 5xx alarm exists
- Dashboard exists

### Design Rationale

TLS terminates at the ALB. Private instances never see public traffic. This is the standard ingress model used across AWS‑native SaaS platforms.

---

## Bonus C: Route53 + ACM DNS Validation

### Objective

Serve the application via a real domain with HTTPS.

### Implementation

- Route53 hosted zone for `arcanum-base.click`
- ACM certificate validated via DNS
- `app.arcanum-base.click` ALIAS → ALB

### Verification

- Hosted zone exists
- ALIAS record resolves to ALB
- Certificate status = ISSUED
- HTTPS request returns HTTP 200

### Note on DNS Duplication

Two hosted zones briefly existed due to iterative Terraform applies. This was resolved by consolidating records into a single authoritative zone and validating delegation against the registrar.

---

## Bonus D: Apex Domain + ALB Access Logs

### Objective

Add operational observability and DNS completeness.

### Implementation

- Zone apex (`arcanum-base.click`) ALIAS → ALB
- ALB access logging enabled
- Logs delivered to S3 with correct bucket policy

### Verification

- Apex record exists
- ALB attributes show logging enabled
- Log objects appear in S3 after traffic generation

### Why This Matters

Access logs are essential for:
- Incident response
- Traffic analysis
- Correlating WAF events with backend failures

---

## Bonus E: WAF Logging

### Objective

Make security events observable.

### Implementation

- WAF logging enabled
- Destination: CloudWatch Logs
- Log group name follows AWS‑required prefix (`aws-waf-logs-*`)

### Verification

- Logging configuration attached to Web ACL
- Log streams populate after traffic
- Events visible via `filter-log-events`

This completes the security feedback loop: **WAF → ALB → Logs → Alarms**.

---

## What This Project Demonstrates

This lab proves I can:

- Design secure AWS architectures
- Implement least‑privilege IAM
- Eliminate SSH and public IPs responsibly
- Debug real connectivity and dependency issues
- Use Terraform the way teams actually do
- Verify infrastructure with authoritative CLI evidence
- Explain *why* decisions were made, not just *what* was built

This is not theoretical knowledge. This is applied cloud engineering.

---

## Closing

If handed this repository during an interview, I would be comfortable:
- Whiteboarding the architecture
- Defending every security decision
- Explaining trade‑offs
- Debugging failures live

That is the standard I built this to.

— **Ahmad K. Qadafi**

