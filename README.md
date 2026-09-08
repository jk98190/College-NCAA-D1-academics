# College Value vs. Athletics Outcomes — SQL Analysis

Exploring whether college affordability, earnings outcomes, and financial aid data connect to NCAA athletics performance and program breadth, using SQL across four linked datasets.

## Overview

This project investigates two datasets that don't obviously belong together: U.S. College Scorecard-style data on cost, debt, earnings, and admissions (`college_value_combined_clean`), and NCAA Academic Progress Rate (APR) athletics data (`database_clean`), joined on institution name. Two coverage-tracking tables (`coverage_report`, `coverage_missing`) are used to audit how complete and reliable that name-based join actually is before drawing conclusions from it.

All analysis is written in SQL — no ORM, no notebook — focused on correlation queries, ranked leaderboards, cross-dataset joins, and a data-quality health check that should arguably be run *before* any of the substantive queries.

## Questions Answered

**Academic value & affordability**
- Does admission selectivity or SAT score correlate with post-grad earnings?
- Which schools have the worst debt-to-earnings ratio for their graduates?
- How does Pell Grant share relate to net price, across income brackets?
- Which schools deliver the most earnings per dollar of published cost?

**Athletics performance**
- How has APR (Academic Progress Rate) trended by NCAA division from 2004 to 2014?
- Which sports show the strongest (or weakest) correlation between athlete eligibility and retention?
- Do schools with more sports programs have better institutional completion rates?
- Do NCAA divisions map to different earnings/debt outcomes at the school level?

**Cross-dataset & data quality**
- Is there a relationship between a school's academic completion rate and its athletes' APR scores?
- Where is athletics data coverage weakest, and which sports/divisions are most affected?
- Are missing-coverage schools disproportionately smaller or lower-resourced?
- **Name-matching health check:** how many schools in each dataset actually match by name, and how many fall through the cracks?

## Structure

The file is organized as 17 independent, numbered/labeled queries (`#1`–`#11`, `#B`–`#F`), each preceded by a one-line comment describing the business question it answers. Query `#F` is a diagnostic and is meant to be run first — it reports how many institutions match cleanly across datasets via `LOWER(TRIM(...))` name normalization, so join results elsewhere in the file can be read with the right amount of confidence.

## Key Techniques

- **Manual Pearson correlation** computed in raw SQL (no built-in `CORR()` function assumed), with `NULLIF` guards against divide-by-zero on zero-variance subsets
- **Window functions** (`ROW_NUMBER() OVER (PARTITION BY ...)`) to resolve a school's most common NCAA division from repeated program-level rows
- **Derived tables / subquery aggregation** to roll up per-sport athletics rows into one row per school before joining to institutional data
- **Fuzzy-safe joins** via `LOWER(TRIM(...))` matching to handle casing/whitespace inconsistencies in institution names across sources
- **Coverage/data-quality auditing** as a first-class part of the analysis, not an afterthought

## Key Findings

*(fill in once you've run the final queries — e.g. correlation coefficients, top/bottom schools, match rate from Query F)*

- Admission selectivity vs. earnings: `corr = ___`
- SAT average vs. earnings: `corr = ___`
- Name-match rate between datasets: `___ / ___` schools matched (`__%`)
- [Add 2–3 more standout numbers here before publishing]

## Data Sources

- College cost/earnings/debt data: [source, e.g. College Scorecard]
- NCAA APR / eligibility / retention data: [source, e.g. NCAA public data]

## Tools

SQL (MySQL dialect — uses backtick identifiers, `POW()`, window functions)

## Notes on Limitations

- Joins rely on exact (normalized) name matching rather than a stable institution ID; Query F quantifies how much this costs in coverage.
- Correlation ≠ causation — especially for the athletics-breadth-vs-completion-rate question, where selection effects (well-resourced schools can afford both more sports and better completion rates) are a likely confound.
