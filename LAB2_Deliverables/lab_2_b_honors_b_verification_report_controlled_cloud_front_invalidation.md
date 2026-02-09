# Lab 2B – Honors B Verification Report

**Module:** Lab 2B Honors B – CloudFront Invalidation as a Controlled Operation  
**Project:** Arcanum  
**Author:** Ahmad K. Qadafi

---

## 1. Objective (Honors B)

Honors B validates that CloudFront invalidation is treated as a **controlled, auditable, last-resort operation**, not a routine deployment mechanism.

The requirements are:
- Use invalidation only for approved “break-glass” scenarios
- Invalidate the **smallest possible blast radius**
- Track invalidation lifecycle to completion
- Prove cache refresh via headers

---

## 2. Break-Glass Invalidation Procedure

To avoid shell quoting errors and preserve auditability, the invalidation batch was defined in a JSON file.

### 2.1 Invalidation Definition

```json
{
  "Paths": {
    "Quantity": 1,
    "Items": ["/static/index.html"]
  },
  "CallerReference": "break-glass-index-20260207"
}
```

---

### 2.2 Create Invalidation (CLI)

```bash
aws --region us-east-1 cloudfront create-invalidation \
  --distribution-id EPDGFAY03D8BQ \
  --invalidation-batch file://invalidation.json
```

**Result:**
```text
Invalidation ID: I1188ZJ5ME2VN0O83JIVRR05ZL
Status: InProgress
```

---

### 2.3 Track Invalidation Completion

```bash
aws --region us-east-1 cloudfront get-invalidation \
  --distribution-id EPDGFAY03D8BQ \
  --id I1188ZJ5ME2VN0O83JIVRR05ZL
```

**Result:**
```text
Status: Completed
```

**Status:** ✅ PASS fileciteturn9file1

---

## 3. Correctness Proof (Before & After)

### 3.1 After Invalidation (Fresh Fetch)

```bash
curl -I https://arcanum-base.click/static/index.html | sed -n '1,30p'
```

**Observed Headers:**
```text
X-Cache: Miss from cloudfront
Cache-Control: public, max-age=86400, immutable
```

**Interpretation:**
- Cached object was purged
- CloudFront fetched fresh content from origin

**Status:** ✅ PASS

---

## 4. Invalidation Policy (Required Paragraph)

CloudFront invalidation is reserved for explicit “break-glass” scenarios such as stale HTML entrypoints after deployment, security incidents, corrupted content, or legal takedowns. For normal deployments, static assets are versioned (for example, `/static/app.<hash>.js`), allowing new content to be deployed without invalidation and ensuring predictable caching behavior. Wildcard invalidations (`/*`) are restricted because they purge the entire cache, increase cost, spike origin load, and undermine cache efficiency; they are permitted only for catastrophic incidents and require explicit justification and documentation. By limiting invalidations to the smallest possible blast radius, caching remains efficient, safe, and operationally controlled.

---

## 5. Incident Scenario (2–5 Sentences)

After deployment, users continued receiving an outdated `index.html` that referenced old static assets. Cache inspection confirmed CloudFront was serving a cached HTML entrypoint while versioned assets were otherwise correct. Because the entrypoint itself was stale, a targeted invalidation of `/static/index.html` was performed instead of a wildcard invalidation. After completion, CloudFront served fresh content, confirmed by an `X-Cache: Miss from cloudfront` response.

---

## 6. Conclusion

Honors B requirements are fully met.

This verification demonstrates:
- Correct use of CloudFront invalidation
- Minimal blast radius
- Full lifecycle tracking
- Header-based proof of cache refresh

This is production-grade cache hygiene, not ad-hoc cache clearing.

— **Ahmad K. Qadafi**

