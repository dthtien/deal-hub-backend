# OzVFY — Next Phase Plan

## A. AI Features

### 1. Price History + Smart Buy Alerts
- `price_histories` table tracks price over time per product
- Crawlers record a PriceHistory entry after every upsert (only if price changed)
- Product model exposes: `average_price_90_days`, `price_trend`, `best_deal?`
- API: `GET /api/v1/deals/:id/price_history` returns last 30 price points
- Price Alert: user sets email + target price; `PriceAlertCheckerJob` runs 3x/day, triggers email and marks alert as triggered

### 2. Personalised Recommendations
- Existing `click_trackings` table captures per-product clicks (already built)
- Future: track session/user_id in click_trackings, add recommendations endpoint
  `GET /api/v1/deals/recommendations?store=ASOS&categories=men`

### 3. Deal Score / AI Rating
- Computed on Product model from: discount %, 90-day price history, click popularity
- Score 1–10 exposed in `as_json`; frontend renders colored badge

## B. Marketing Strategy

### 1. Reddit Automation
- PostBargainJob already posts to social; extend to r/AusDeals, r/frugal_oz
- Only post deals with deal_score >= 8

### 2. Weekly Email Newsletter
- `WeeklyNewsletterJob` runs Monday 9am AEST
- Top 10 deals by deal_score in the last 7 days
- Sends HTML email via ActionMailer to all active subscribers

### 3. SEO Store Pages
- `GET /api/v1/stores` — list all stores with deal count + best deal
- `GET /api/v1/stores/:name/deals` — paginated deals for one store with SEO metadata

### 4. Price Alert Virality Loop
- After setting a price alert, user receives a shareable link
- "Share this deal" CTA on the confirmation email

## Implementation Priority
1. Price History (migration + model + crawler hook + API endpoint)
2. Deal Score (computed from price history)
3. Price Alert (migration + model + controller + job + mailer)
4. SEO Store Pages (backend endpoints)
5. Weekly Newsletter (job + mailer template)
6. Frontend: deal score badge, price trend arrow, best deal banner, alert modal, store pages
