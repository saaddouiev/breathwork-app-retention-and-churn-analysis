# Breathwork App: Activation, Engagement & Churn Analysis

A SQL-only analysis of a subscription breathwork app (synthetic data), tracing the path from acquisition channel → trial engagement → churn. Built entirely in PostgreSQL, with matplotlib for every chart.

## The Question

Where in the customer lifecycle is this business actually losing people, and is
it a pricing problem or an engagement problem?

## Data & Architecture

Unlike my other two portfolio projects, which each analyze a single flat transactions table, this one uses a synthetic subscription-app dataset spanning six related source tables across three business processes, trial/activation, usage, and subscription/billing. That relational complexity is what a star schema is for.

Raw source tables are cleaned and modeled directly into 2 fact tables sharing 3 dimensions:

<img width="2399" height="2316" alt="data_model" src="https://github.com/user-attachments/assets/284f11a0-2e74-4e2c-a9c0-247bffd17014" />

| Table | Grain |
| :--- | :--- |
| `fact_engagement` | One row per content interaction (sessions with no interaction are kept as empty rows, so no activity is accidentally dropped) |
| `fact_subscription` | One row per subscription (not per user because 11% of users have held more than one subscription over time) |
| `dim_user` | One row per user |
| `dim_content` | One row per piece of content |
| `dim_date` | One row per calendar date |

## Key Findings

### 1. Churn reads as an engagement problem, not a pricing problem

<img width="2967" height="1469" alt="04_cancellation_reasons" src="https://github.com/user-attachments/assets/d4059359-0d75-4b4d-bde3-90cca48d2aa2" />

`not_using_enough` (6,273 users) is nearly 2x the count of `too_expensive`
(3,808), well ahead of `found_alternative` (2,825) and `no_reason_given`
(2,765). Price is a real factor, but it isn't the dominant one — usage drop-off
is.

### 2. The retention cliff is steepest between week 4 and month 3

<img width="2970" height="1469" alt="02_retention_curve" src="https://github.com/user-attachments/assets/fadc2868-3038-4657-ad34-9ec353e718c3" />

Cohort retention: 100% (week 1) → 82% (week 4) → 47% (month 3) → 15% (month 6).
The first month holds up reasonably well; the real collapse (82% → 47%, a
35-point drop) happens between week 4 and month 3 — that's the window where
this business is losing the most people.

### 3. Churned users never build a habit — they plateau at ~1.4 sessions/week

<img width="3570" height="1470" alt="03_engagement_trajectory" src="https://github.com/user-attachments/assets/04066fac-3f0a-4b72-bd57-4a94b294b107" />

Tracked monthly from Jan 2024–Dec 2025, churned users' average sessions/week
hover in a tight band (~1.1–1.7) around a ~1.4 plateau for the entire window —
never breaking past ~1.5. This is consistent with #1: usage stagnation is
visible as an ongoing pattern, not just a symptom that shows up right before
cancellation.

### 4. Acquisition channel quality predicts trial conversion

<img width="2970" height="1468" alt="05_conversion_by_channel" src="https://github.com/user-attachments/assets/f8b160b0-860d-4eb9-98a6-5771784d57ac" />

Trial-to-paid conversion ranges from 62.9% (referral) and 60.0%
(organic_search) down to 46.2% (paid_social) — a 16.7-point gap between the
best and worst channel. Referral and organic outperform every paid channel.

### 5. Monthly plans churn 20 points higher than annual

<img width="2370" height="1469" alt="01_churn_by_plan" src="https://github.com/user-attachments/assets/ca7bc83c-73cb-4946-aab1-d2176e1f4a14" />

Monthly churn sits at 55.7% vs. 35.5% for annual. This could reflect lower
switching friction on monthly, or a selection effect where annual buyers are
already more committed at signup — the data here can't distinguish the two.

## So What

The insight: **channels that bring in lower-intent users (paid_social)
convert worse at trial, and the users who do convert but never escalate past
~1.4–1.5 sessions/week are the same ones who later cancel citing "not using
enough" rather than price** — and the point where that shows up as churn is
mainly around the month 1 to month 3 window.

Recommendations:

- Reallocate acquisition spend away from paid_social. Referral converts trial-to-paid at 62.9% vs. 46.2% for paid_social — a 16.7-point gap. Pull trial volume by channel next to size this in actual users before shifting budget, but the direction is clear.

- Retention spend should go to engagement, not discounts. Not_using_enough causes 65% more cancellations than too_expensive (6,273 vs. 3,808). Kill or shrink price-led win-back offers; build a habit-formation push — content recommendations, streak nudges — targeted at the week-4-to-month-3 window, where retention falls from 82% to 47%.

- Close the monthly-vs-annual churn gap with a mid-trial upgrade push. Monthly churns at 55.7% vs. 35.5% for annual. Test a discounted annual-upgrade offer surfaced around day 20-25, just before the cliff.

# Limitations

  This analysis covers trial activation, engagement cadence, and churn attribution. DAU/MAU and MRR were not tracked — the available tables support session-level and subscription-level analysis, not daily active-user or recurring-revenue reporting.

## Repository Structure

```
breathwork_mart_activation.sql   -- mart_user_activation + supporting queries
breathwork_mart_engagement.sql   -- mart_engagement + cohort retention query
breathwork_mart_churn.sql        -- mart_churn + churn-rate queries
charts/
  01_churn_by_plan.png
  02_retention_curve.png
  03_engagement_trajectory.png
  04_cancellation_reasons.png
  05_conversion_by_channel.png
```

## Limitations

- Data is synthetic, generated for project purposes, patterns mimic are world data but not real user behavior.
- All findings above are descriptive/correlational. 
