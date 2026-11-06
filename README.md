# My Project Title

# Who Is Driving Irish Mortgage Lending?

First-time buyers took 74% of house purchase mortgage approvals in Ireland in 2025, compared with 56% in 2015. I wanted to see what that shift looks like in the data, whether the housing market is becoming more dependent on mortgages, and whether arrears risk is building at the same time.

## Why I did this

I come from an analytics background, not finance, so I picked a topic I had to learn properly. I also wanted to work with messy public data instead of a clean Kaggle dataset, and to check my numbers against what the publishers themselves report. The stakeholders (a mortgage product team and a credit risk team at an Irish lender) are hypothetical, but the data is real.

## Findings

| Finding | Evidence |
|---|---|
| First-time buyers are now about three in four house purchase approvals | 56.2% in 2015, 74.2% in 2025 |
| Movers and buy-to-let investors have shrunk | Movers fell from 33.0% to 19.3% of all approvals, buy-to-let from 5.5% to 1.6% (2015 to 2025) |
| The market relies more on mortgages than it did (indicative) | Purchase approvals per market-price sale went from 0.55 in 2015 to around 0.75 since 2020 |
| Serious arrears have fallen steadily | Owner-occupier mortgages over 90 days in arrears peaked at 12.85% in September 2013 and were 3.13% in December 2025 |

## Data

- **BPFI Mortgage Approvals** data series, monthly, Jan 2011 to Sep 2026 (bpfi.ie, Publications)
- **Central Bank of Ireland** Residential Mortgage Arrears and Repossession Statistics, quarterly, Sep 2009 to Mar 2026 (data.gov.ie)
- **Property Price Register**, every residential sale, Jan 2010 to Oct 2026 (propertypriceregister.ie)

The data files aren't in this repo because of their size, but all three are free to download.

## How it's built

PostgreSQL, in four layers:

```
raw       files loaded as they are, all text
clean     dates and numbers converted, problems fixed or flagged
dq        27 data quality checks with pass/fail results
analysis  views for each question
```

I loaded everything as text first so nothing could be lost on import, and did all the fixing in SQL so every change can be counted. The scripts in `/sql` run in number order.

## What I ran into

The data needed more work than I expected. A few examples:

- In the BPFI file, approvals before July 2014 aren't split by buyer type. The total sits in a merged Excel cell, and when saved as CSV it lands in the first-time buyer column. If I hadn't caught that, June 2014 would have shown first-time buyers at 92.5% of the market.
- The Central Bank file has two quarters dated on the 1st of the month instead of the quarter end (all of Q4 2025, and part of Q3 2025). For Q3, every euro figure was on 01/09 and every count on 30/09, which pointed to a date error rather than a separate report. I moved both to the quarter end and treated it as an assumption.
- March 2026 in the same file is missing some total rows for banks, so my arrears trend stops at December 2025.
- The Property Price Register has 511 sales over €10 million, one of them €387.7 million for a single house address. I flagged these, along with 1,092 duplicates and 41,490 sales declared below market price, and left them out of price figures. I didn't delete anything.

## Checking my numbers

I compared my results with figures the publishers released themselves:

| Check | Published | Mine |
|---|---|---|
| BPFI total approvals, 2021 | 53,335 (BPFI press release, 26 Jan 2022) | 53,335 |
| Central Bank, owner-occupier mortgages, March 2020 | 739,592 accounts, 63,437 in arrears, 41,079 over 90 days (5.6%) | Match |
| Central Bank, owner-occupier mortgages, December 2020 | 731,988 accounts, 54,986 in arrears, 38,785 over 90 days (5.3%) | Match |

## Limitations

- Approvals are offers, not loans. Some people get approved by more than one lender, and some approvals expire.
- The approvals-to-sales figure is only indicative. Cash buyers show up in sales but not in approvals, and timing between the two isn't exact.
- The buyer-type breakdown only exists from July 2014.
- New home prices in the Property Price Register don't include VAT.

## Next

- Median prices by county
- A Power BI dashboard on top of the analysis views

**Tools:** PostgreSQL, DBeaver, SQL (CTEs, window functions, CASE, views)