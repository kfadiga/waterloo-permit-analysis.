# Waterloo Building Permit Trends (1999-2025)

R analysis of 33,000+ City of Waterloo building permits: how permit volume, construction value, permit types, and seasonality have changed over 27 years.

![Permits per year](charts/01_permits_per_year.png)
![Construction value](charts/02_construction_value.png)
![Permits by type](charts/03_permits_by_type.png)
![Seasonality](charts/04_seasonality.png)

## Question
How has building activity in the City of Waterloo changed over time, and when in the year does it peak?

## Data
City of Waterloo Building Permits (Open Data, ArcGIS Hub): https://hub.arcgis.com/datasets/9319ff78ff074327acb9e2e084e30b2c

33,450 records (33,446 after removing duplicates), covering permits with status Issued, Complete, or Occupancy Final. The dataset has no license attached, so the raw file is not included here. To rerun the script, download the CSV from the link above and save it in the project folder.

## Methods
- R (tidyverse, lubridate, janitor, ggplot2)
- Parsed issue dates, removed duplicate permit IDs, and set non-positive and implausible construction values to missing
- Aggregated by year, permit type, and month; fitted a linear trend to annual permit counts
- Excluded the current partial year from trend calculations

## Key findings
- Permit volume peaked in the early 2000s. 2002 was the busiest year (2,103 permits), followed by 2003, 2000, 2001, and 2004.
- Permits have declined since: about 27 fewer permits per year across 1999-2025, and about 11 fewer per year since 2010.
- Value per permit is rising even as counts fall. Median construction value was about $30,000 in 2010 and about $42,000 in 2024. Total construction value was highest in 2010 ($765M), 2024 ($589M), and 2016 ($581M).
- Permits are seasonal: they peak in May-July (about 130 per month on average) and are lowest in January-February (about 60 per month).

## Data quality notes
- One 1999 commercial permit was recorded at $2.8 billion, roughly 200 times the next-largest permit that year. I treated it as a likely data-entry error and excluded its value (the permit still counts toward permit totals). Any single permit over $500M is handled this way; only this one record is affected.
- The units field is incomplete for recent permits (92 new residential units recorded in 2025 versus 859 in 2024), so housing-unit trends are not reported.
- Permit type labels appear to change around 2008 (many categories before, mostly "Residential Building Permit" and "Non Residential" after), likely a change in the city's classification. The permits-by-type chart is shown for context, and type trends across the full period should not be over-interpreted.
- Construction values are as recorded at issuance and are not adjusted for inflation.

## Files
- `clean_analysis.R`: full cleaning, analysis, and charting script
- `yearly_summary.csv`, `permits_by_type.csv`: aggregated results
- `charts/`: chart images
