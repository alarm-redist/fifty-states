# 2020 Missouri Congressional Districts

## Redistricting requirements
In [Missouri](https://revisor.mo.gov/main/OneSection.aspx?section=III%20%20%2045&constit=y), districts must:

1. be contiguous
1. have equal populations
1. be geographically compact

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%. 
We apply a basic county constraint to be in line with the splits in the plan, though there is no legal requirement.
We add a VRA constraint targeting one BVAP opportunity district.

## Data Sources
Data for Missouri comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Missouri.
We use a standard algorithmic county constraint.
No special techniques were needed to produce the sample.
