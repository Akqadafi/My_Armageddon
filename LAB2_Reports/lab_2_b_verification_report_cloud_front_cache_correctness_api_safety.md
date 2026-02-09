# Lab 2B – Verification Report

**Module:** Lab 2B – CloudFront Cache Correctness (Static vs API)  
**Project:** Arcanum  
**Author:** Ahmad K. Qadafi

---

## 1. Purpose of Lab 2B

Lab 2B focuses on **cache correctness**, not raw performance.

The goal is to prove that CloudFront is configured so that:
- **Static content** is cached aggressively (fast, cheap, safe)
- **API responses** are *not* cached unsafely (no stale reads, no cross-user data leaks)
- Cache keys include the **minimum necessary variance**
- Origin request policies forward **only what the origin actually needs**

This lab mirrors one of the most common real-world CDN failure modes: *misconfigured caching that causes security or data-consistency incidents*.

---

## 2. Architecture Context

**Traffic Flow**

Client → CloudFront → ALB (origin-cloaked) → Private EC2 → RDS

**CloudFront Behaviors (Lab 2B scope):**
- `/static/*` → aggressively cached
- `/api/*` → safe default (no caching, origin-driven)

---

## 3. Deliverables Implemented

### Terraform Controls

- **Two cache policies**
  - Static: aggressive caching
  - API: caching disabled / origin-controlled

- **Two origin request policies**
  - Static: minimal forwarding
  - API: forwards required headers / query strings only

- **Two cache behaviors**
  - `/static/*` → static cache + static ORP
  - `/api/*` → API cache + API ORP

- **Response headers policy** (Be A Man Challenge)
  - Explicit `Cache-Control` headers for static content

---

## 4. Cache Policy Intent (Design Explanation)

### 4.1 Static Content (`/static/*`)

**Cache key includes:**
- Path only

**Cache key excludes:**
- Query strings
- Cookies
- Headers

**Why:**
Static assets are immutable. Including high-cardinality values would fragment the cache and reduce hit ratio with no correctness benefit.

---

### 4.2 API Content (`/api/*`)

**Cache behavior:**
- Caching disabled (TTL = 0)

**Origin forwarding:**
- Path
- Required headers
- Required query strings

**Why:**
APIs may return user-specific or rapidly changing data. Safe default is *do not cache* unless explicitly proven safe.

This prevents:
- User A seeing User B’s data
- Stale reads after writes
- Authentication leakage

---

## 5. Verification: Static Content Caching

### 5.1 First Request (Cache Miss)

```bash
curl -I https://arcanum-base.click/static/example.txt
```

**Result (excerpt):**
```text
Cache-Control: public, max-age=86400, immutable
X-Cache: Miss from cloudfront
```

---

### 5.2 Second Request (Cache Hit)

```bash
curl -I https://arcanum-base.click/static/example.txt
```

**Result (excerpt):**
```text
X-Cache: Hit from cloudfront
Age: 1
```

**Interpretation:**
- Object cached successfully
- Age header increases on subsequent requests

**Status:** ✅ PASS

---

### 5.3 Query String Sanity Check

```bash
curl -I "https://arcanum-base.click/static/example.txt?v=1"
curl -I "https://arcanum-base.click/static/example.txt?v=2"
```

**Result:**
```text
X-Cache: Hit from cloudfront
Age: > 0
```

**Interpretation:**
- Query strings ignored for static cache key
- Both requests map to same cached object

**Status:** ✅ PASS

---

## 6. Verification: API Safety (No Caching)

### 6.1 First API Request

```bash
curl -I https://arcanum-base.click/api/list
```

**Result (excerpt):**
```text
X-Cache: Miss from cloudfront
Age: (absent)
```

---

### 6.2 Second API Request

```bash
curl -I https://arcanum-base.click/api/list
```

**Result (excerpt):**
```text
X-Cache: Miss from cloudfront
Age: (absent)
```

**Interpretation:**
- API responses are not cached
- Each request reaches the origin

**Status:** ✅ PASS

---

## 7. Stale-Read Safety Test

```bash
curl -i "https://arcanum-base.click/api/add?note=hello"
curl -i https://arcanum-base.click/api/list
```

**Result:**
```text
Inserted note: hello
<h3>Notes</h3><ul><li>1: hello</li></ul>
```

**Interpretation:**
- Write immediately reflected in subsequent read
- No cached API response served

**Status:** ✅ PASS

---

## 8. Cache Key & Forwarding Summary

| Path | Cached? | Cache Key | Forwarded to Origin |
|---|---|---|---|
| `/static/*` | Yes | Path only | Minimal |
| `/api/*` | No | N/A | Required headers / params |

---

## 9. Incident Scenarios Prevented

This configuration explicitly prevents:
- User A seeing User B’s cached API response
- Random 403s caused by over-forwarded headers
- Cache hit ratio collapse due to cache fragmentation
- Stale reads after writes

---

## 10. Conclusion

Goals Achieved:
- Uses caching where safe
- Avoids caching where dangerous
- Proves correctness with headers and behavior

This is the difference between a CDN that *works* and a CDN that *won’t page you at 2 a.m.*.

— **Ahmad K. Qadafi**

