# Lab 2B – Honors A Verification Report

**Module:** Lab 2B Honors A – Origin-Driven Caching (CloudFront)  
**Project:** Arcanum  
**Author:** Ahmad K. Qadafi

---

## 1. Objective (Honors A)

The goal of Honors A is to demonstrate **origin-driven caching** for API endpoints:

- CloudFront **caches only when the origin explicitly allows it**
- Cache behavior is controlled by `Cache-Control` headers, not guesswork at the edge
- Private or sensitive endpoints are **never cached**

This pattern keeps cache authority with the application and prevents accidental data leaks.

---

## 2. Design Summary

**Endpoints implemented:**

| Endpoint | Cache Policy | Purpose |
|---|---|---|
| `/api/public-feed` | `public, s-maxage=30` | Safe, shared cache |
| `/api/list` | `private, no-store` | Never cache |

CloudFront is configured with a managed **UseOriginCacheControlHeaders** cache policy, meaning:
- If the origin sends cacheable headers → CloudFront caches
- If the origin does not → CloudFront does not cache

---

## 3. Terraform Evidence

A successful Terraform apply confirms in-place update:

```text
Resources: 0 added, 8 changed, 0 destroyed

New Output:
arcanum_private_route_table_id = rtb-0361bb4fd188b4c85
``` 

The new output arcanum_private_route_table_id = rtb-0361bb4fd188b4c85 confirms Terraform successfully created/recorded the private routing layer used by your private subnets. This proves the   environment now has an declaried route table controlling how private instances reach AWS services (typically via VPC endpoints and/or NAT), which is critical for “private-by-default” networking and for keeping management traffic (SSM, Secrets Manager, CloudWatch Logs, etc.) off the public internet.

---

## 4. Verification: Public Endpoint (`/api/public-feed`)

### 4.1 First Request (Expected MISS)

```bash
curl -i https://arcanum-base.click/api/public-feed | sed -n '1,20p'
```

**Observed Headers:**
```text
Cache-Control: public, s-maxage=30, max-age=0
X-Cache: Miss from cloudfront
```

**Body Evidence:**
```json
{"server_time_utc":"2026-02-06T18:46:55.722338+00:00","message":"Hello from arcanum public feed"}
```

---

### 4.2 Second Request Within TTL (Expected HIT)

```bash
curl -i https://arcanum-base.click/api/public-feed | sed -n '1,20p'
```

**Observed Headers:**
```text
X-Cache: Hit from cloudfront
Age: 25
```

**Interpretation:**
- CloudFront cached the response
- `Age` confirms shared-cache TTL behavior
- Body remained identical during the TTL window

**Status:** ✅ PASS

---

### 4.3 TTL Expiry (Expected MISS)

```bash
sleep 35
curl -i https://arcanum-base.click/api/public-feed | sed -n '1,20p'
```

**Observed:**
```text
X-Cache: Miss from cloudfront
```

**Interpretation:**
- Cache expired
- Fresh origin response served

**Status:** ✅ PASS

---

## 5. Verification: Private Endpoint (`/api/list`)

```bash
curl -i https://arcanum-base.click/api/list | sed -n '1,30p'
curl -i https://arcanum-base.click/api/list | sed -n '1,30p'
```

**Observed Headers:**
```text
Cache-Control: private, no-store
X-Cache: Miss from cloudfront
```

**Interpretation:**
- No caching occurs
- Each request reaches the origin
- Prevents stale reads and cross-user data exposure

**Status:** ✅ PASS

---

## 6. Safety Rationale 

Origin driven caching is safer for APIs because it keeps the cache authority with the application rather than the CDN. By explicitly stating cacheability with headers like `Cache-Control: public, s-maxage=30` or `private, no-store`, the application ensures that only deterministic, user-neutral responses are cached. This prevents accidental exposure of user-specific data, and allows cache behavior to evolve alongside application code without redeploying the infrastructure. Caching should still be fully disabled for endpoints that return personalized, security-sensitive, or rapidly changing data—such as authenticated user feeds, financial transactions, or administrative views—where correctness and privacy outweigh latency benefits.

---

## 7. Conclusion

CloudFront goals achieved:
- Honors origin cache directives
- Caches shared-safe responses
- Never caches private endpoints

This demonstrates safe, production-grade CDN behavior for dynamic APIs.

— **Ahmad K. Qadafi**

