# Australian Store Crawler Research Report

## Summary

Researched 15 Australian online stores for crawlability. Found 2 new Shopify stores that were implemented. 13 stores were blocked or not viable.

---

## Tier 1 — High Priority

| Store | Shopify? | Public API? | Feasibility | Notes |
|-------|----------|-------------|-------------|-------|
| Catch.com.au | ❌ | ❌ | ❌ Blocked | Returns 403 on collections endpoint |
| Chemist Warehouse | ❌ | ❌ | ❌ Not feasible | Custom platform, 404 on Shopify endpoint |
| Harvey Norman | ❌ | ❌ | ❌ Not feasible | Custom platform, 404 on Shopify endpoint |
| Dan Murphy's | ❌ | ❌ | ❌ Blocked | Returns 403, bot protection active |
| Rebel Sport | ❌ | ❌ | ❌ Not feasible | Returns 410 Gone on Shopify endpoint |
| Priceline | ❌ | ❌ | ❌ Blocked | NOINDEX/NOFOLLOW headers, bot protection |
| Supercheap Auto | ❌ | ❌ | ❌ Not feasible | Returns 410 Gone on Shopify endpoint |
| BCF | ❌ | ❌ | ❌ Not feasible | Returns 410 Gone on Shopify endpoint |
| Anaconda | ❌ | ❌ | ❌ Not feasible | Connection timeout/refused |
| Cotton On | ❌ | ❌ | ❌ Not feasible | Returns 410 Gone on Shopify endpoint |

---

## Tier 2 — Medium Priority

| Store | Shopify? | Public API? | Feasibility | Notes |
|-------|----------|-------------|-------------|-------|
| Lorna Jane | ❌ | ❌ | ❌ Not Shopify | Uses custom platform at `/collection/` (not `/collections/`), no products.json |
| Universal Store | ✅ | ✅ | ✅ **IMPLEMENTED** | Shopify, `/collections/sale/products.json` returns 250 products |
| Beginning Boutique | ✅ | ✅ | ✅ **IMPLEMENTED** | Shopify, `/collections/sale/products.json` returns 250+ products |
| The Iconic | ➖ Already exists | — | ➖ Skip | Already implemented in existing crawlers |
| Booktopia | ❌ | ❌ | ❌ Not feasible | Custom platform (book store), no Shopify endpoint |

---

## Crawlers Implemented

### 1. Beginning Boutique ✅
- **URL:** https://www.beginningboutique.com.au
- **Method:** Shopify `/collections/sale/products.json`
- **Files created:**
  - `app/crawlers/beginning_boutique_crawler.rb`
  - `app/services/beginning_boutique/base.rb`
  - `app/services/beginning_boutique/crawl_all.rb`
  - `app/jobs/crawlers/beginning_boutique_job.rb`
- **Store constant:** `Product::BEGINNING_BOUTIQUE = 'Beginning Boutique'`

### 2. Universal Store ✅
- **URL:** https://www.universalstore.com.au
- **Method:** Shopify `/collections/sale/products.json`
- **Files created:**
  - `app/crawlers/universal_store_crawler.rb`
  - `app/services/universal_store/base.rb`
  - `app/services/universal_store/crawl_all.rb`
  - `app/jobs/crawlers/universal_store_job.rb`
- **Store constant:** `Product::UNIVERSAL_STORE = 'Universal Store'`

---

## Test Results

All 96 existing tests pass (0 failures, 1 pending/skipped).

## Commit

```
d6207c1 Add crawlers for Beginning Boutique and Universal Store via Shopify JSON API
```
Pushed to `origin/main`.
