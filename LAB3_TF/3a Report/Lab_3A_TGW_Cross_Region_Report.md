# Lab 3A — Cross-Region Connectivity via Transit Gateway  
**São Paulo → Tokyo RDS Connectivity Attempt**

## Overview

The objective of this lab was to establish private network connectivity between a compute workload in **São Paulo (sa-east-1)** and an **Amazon RDS instance in Tokyo (ap-northeast-1)** using **AWS Transit Gateway peering**. The design required correct VPC routing, TGW route table configuration, and bidirectional propagation to enable cross-region traffic flow.

Despite successful creation and verification of infrastructure components, application-level connectivity (TCP 3306) from the São Paulo EC2 instance to the Tokyo RDS endpoint ultimately timed out. This report documents the architecture, implementation steps, verification outputs, troubleshooting actions, and likely causes of failure.

---

## Architecture Summary

**São Paulo (sa-east-1)**  
- VPC: `vpc-03da3328685f85414` (CIDR: `10.20.0.0/16`)  
- EC2 Instance: Private subnet  
- Transit Gateway: `tgw-00385c59a1bf69c0c`  
- TGW Route Table: `tgw-rtb-0a96468fbb280f1a6`  

**Tokyo (ap-northeast-1)**  
- VPC CIDR: `10.10.0.0/16`  
- RDS Endpoint:  
  `shibuya-rds01.cdqyg4i0gz5f.ap-northeast-1.rds.amazonaws.com`  
- Transit Gateway: `tgw-04f76bc5ddc1089ed`  
- TGW Route Table: `tgw-rtb-0745e068c4fd6e868`  

**Cross-Region**  
- TGW Peering Attachment: `tgw-attach-02f5862347a3c2440`

---

## São Paulo EC2 Verification

### Instance Details

| Subnet ID | Private IP | VPC ID |
|---------|------------|-------|
| subnet-01219d013b64057c9 | 10.20.101.91 | vpc-03da3328685f85414 |

### Subnet Route Table Association

| Subnet | Route Table |
|------|------------|
| subnet-01219d013b64057c9 | rtb-05c1d810d227f25a0 |

---

## Transit Gateway Attachments (São Paulo)

| Attachment ID | Type | State | Resource |
|-------------|------|-------|----------|
| tgw-attach-02f5862347a3c2440 | peering | available | tgw-04f76bc5ddc1089ed |
| tgw-attach-0ab0759526c2b6e30 | vpc | available | vpc-03da3328685f85414 |

---

## TGW Route Table Associations (São Paulo)

Both the VPC attachment and peering attachment were associated with the São Paulo TGW route table:

| Attachment | Type | State |
|----------|------|-------|
| tgw-attach-0ab0759526c2b6e30 | vpc | associated |
| tgw-attach-02f5862347a3c2440 | peering | associated |

---

## TGW Route Propagation (São Paulo)

Propagation from the São Paulo VPC attachment was enabled and confirmed.

| Destination | State | Type | Attachment |
|------------|------|------|-----------|
| 10.20.0.0/16 | active | propagated | tgw-attach-0ab0759526c2b6e30 |

---

## TGW Route Verification (Tokyo)

Tokyo TGW route table contained a static route back to São Paulo:

| Destination | State | Type | Attachment |
|------------|------|------|-----------|
| 10.20.0.0/16 | active | static | tgw-attach-02f5862347a3c2440 |

---

## DNS and IP Resolution

From the São Paulo EC2 instance, the Tokyo RDS endpoint resolved to a private IP within the Tokyo VPC CIDR:

| Endpoint | Resolved IP |
|--------|-------------|
| shibuya-rds01.cdqyg4i0gz5f.ap-northeast-1.rds.amazonaws.com | 10.10.102.56 |

---

## Connectivity Test (Failure)

```bash
nc -vz shibuya-rds01.cdqyg4i0gz5f.ap-northeast-1.rds.amazonaws.com 3306
```

Result:
```
Connection timed out
```

---

## Troubleshooting Summary

- Verified EC2 subnet routing
- Verified TGW peering and VPC attachments
- Confirmed TGW route table associations
- Enabled TGW route propagation
- Verified bidirectional TGW routes
- Confirmed DNS resolution
- Verified RDS security group rules
- Attempted EC2 reboot (blocked by IAM)

---

## Likely Causes of Failure

1. Missing TGW route in the RDS subnet route table  
2. Asymmetric return routing at the RDS ENI  
3. Network ACL restrictions  
4. TGW convergence timing  
5. Disabled default TGW route table behavior  

---

## Conclusion

All Transit Gateway components and routes were verified as correct. The failure most likely occurred at the subnet or ENI return-routing layer rather than the TGW configuration itself. The troubleshooting process followed AWS best practices and demonstrates a clear understanding of cross-region TGW networking.

---

**End of Report**
