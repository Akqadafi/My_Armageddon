# Lab 1C – Terraform Verification Report

## Project
**Lab 1C: Terraform – EC2, IAM, Secrets Manager, SSM**

This document verifies that the Terraform-provisioned infrastructure meets all functional and security requirements for Lab 1C. Verification was performed using AWS CLI commands from both the local environment and inside the EC2 instance via AWS Systems Manager (SSM).

---

## Environment Summary

| Item | Value |
|----|----|
| AWS Region | us-east-1 |
| EC2 Instance ID | i-0286be49d51741c1d |
| IAM Role | arcanum-ec2-role01 |
| Instance Profile | arcanum-instance-profile01 |
| Secret Name | lab1a/rds/mysql |
| RDS Endpoint | arcanum-rds01.coj82qo2k48t.us-east-1.rds.amazonaws.com |
| VPC ID | vpc-0693444b4e91d00ed |

---

## Verification Results Summary

All required verification checks **passed successfully**.

| # | Check | Location | Status |
|---|---|---|---|
| 1 | Secret exists | Local | PASS |
| 2 | EC2 has IAM instance profile | Local | PASS |
| 3 | Instance profile resolves correctly | Local | PASS |
| 4 | IAM role resolves correctly | Local | PASS |
| 5 | Role has Secrets Manager permissions | Local | PASS |
| 6 | EC2 assumes expected role | EC2 (SSM) | PASS |
| 7 | Role can describe secret | EC2 (SSM) | PASS |
| 8 | Role can read secret value | EC2 (SSM) | PASS |
| 9 | No wildcard secret policy | Local | PASS |
| 10 | SSM connectivity healthy | Local | PASS |

---

## Security Posture Notes

- IAM permissions follow least-privilege principles.
- EC2 uses IAM role authentication (no static credentials).
- Secrets are retrieved dynamically at runtime.
- RDS is private and not publicly accessible.
- SSM is used for secure access (no SSH keys required).

---

## Final Status

**Lab 1C Terraform verification complete.**
All infrastructure, IAM, Secrets Manager, and SSM checks passed successfully.
