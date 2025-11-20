# Contributing an Analysis

1. Setting up:
    1. Fork the repository, or create a branch named for your analysis (e.g. `WA_cd_2020`).
    1. Open RStudio and press `Ctrl+Shift+L` or run `devtools::load_all(".")`.
    1. Run `init_analysis("WA", "cd", 2020)` (with your details) to start your
    analysis. Analysis files will be created from the templates and opened
    automatically. See `?init_analysis` for more information.
1. Doing your analysis:
    1. Update the [tracker](https://docs.google.com/spreadsheets/d/1k_tYLoE49W_DCK1tcWbouoYZFI9WD76oayEt5TOmJg4/edit#gid=453387933) 
    to "In progress".
    1. Research the [legal requirements](https://www.ncsl.org/research/redistricting/redistricting-criteria.aspx) for your state.
    1. Edit the provided template to create and run your analysis.
    1. Be particularly careful if you need to merge precincts. The template has specific instructions for this.
    1. We will enforce an R code style guide, based on the tidyverse style guide.
    Run `enforce_style("WA", "cd", 2020)` (with your details) periodically to
    automatically format your code.
    1. Document your analysis in the provided documentation file, including
    decisions on how to incorporate constraints, data sources, and simulation
    techniques.
    1. The 2010-cycle final plan should be saved in the `cd_2010` column.
    The 2020-cycle enacted plan should be saved in the `cd_2020` column and added as a reference plan to the `redist_plans` object.
    1. Any data you need to import into your analysis should be added under `data-raw/`.
    1. Any data you create over the course of your analysis should go under `data-out/`.
    1. No data in either folder should be added to the GitHub.
    1. Don't edit the file paths for the `redist_map`, `redist_plans`, and
    summary statistic outputs.
1. Completing your analysis:
    1. Make sure you have removed all `TODO` lines from the template code.
    1. Make sure your documentation is up-to-date and correct.
    1. Run `git fetch --all` and `git merge origin/main` at the terminal. Rerun the final lines of your `03_sim_` file, which calculates summary statistics.
    3. Run `enforce_style()` one more time.
    4. Create a pull request on GitHub, following the provided template.
    5. As part of the PR template, you will paste in diagnostic plots.
    6. If your state has additional or unusual constraints, provide figures
    justifying your choice of constraint strength and showing that the constraints
    are binding properly.
    1. Tag the graduate student assigned to your state for review. If you are a
    graduate student, tag another.
    1. Add appropriate [labels](https://github.com/alarm-redist/fifty-states/labels) and milestones to your PR, so that it stays organized.
    1. Update the [tracker](https://docs.google.com/spreadsheets/d/1k_tYLoE49W_DCK1tcWbouoYZFI9WD76oayEt5TOmJg4/edit#gid=453387933) 
    to "Draft".
1. Finalizing your analysis
    1. Once your PR has been signed off, it may be merged into the main branch.
    1. In the main branch, run `finalize_analysis("WA", "cd", 2020)` (with your
    details) to finalize your analysis. This will add your generated files to
    the dataverse.
    1. Update the [tracker](https://docs.google.com/spreadsheets/d/1k_tYLoE49W_DCK1tcWbouoYZFI9WD76oayEt5TOmJg4/edit#gid=453387933) 
    to "Validated".
    
    
##  Project-wide Guidelines

1. Any processed data saved as an `.rds` should be compressed with option at
least "gz". (e.g. `readr::write_rds(object, "path.rds", compress = "gz")`)
1. Any _common_ functions to multiple analyses should be in R scripts in the
folder `R/` and should be fully documented using [roxygen](https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html).
Additions to this file should be in their own pull request and reviewed by a
grad student. If you are a grad student, please have a different grad student
review your PR.
1. Please identify the sections of your code with comments that look like
`# Clean Data ----`. This creates a section in RStudio and help signpost what
you did for that section for the reviewer.
1. No data in either folder should be added to the GitHub.

# Understanding Internal Diagnostics

## Plan Weights

**Units**: Weights are defined at the plan level.
 
**Conceptually**:
SMC sequentially creates districts (i.e., `niter` iterations per district).
First SMC splits the state into a district and the rest in a number of different ways
Each split has resampling weights according to the target distribution
SMC resamples splits according to these weights
Repeat this process until each sampled plan is complete with the desired number of districts.

The plot shows the distribution of the final resampled weights for SMC. They are standardized so that they sum to 1.
 
**Check for**: You do not want a small number of plans to have disproportionately large weights. Weights should generally vary by no more than 1-2 orders of magnitude.
 
Formal reference: “Algorithm 2” in the [SMC paper](https://arxiv.org/pdf/2008.06131.pdf). For how its raw values are standardized (many steps), see [`redist` code](https://github.com/alarm-redist/redist/blob/e0521998ebc4b362ce7b95a683a896ea07d038bd/R/redist-smc.R#L128-L133).

## Plan Diversity

**Units**: Plan Diversity is measured for each plan
 
**Conceptually**: How different sampled plans are from one another. A greater VI distance means a more diverse sample, which is desirable.

**Check for**: Plan diversity should ideally be concentrated in the 0.5-1 range, though for very complicated sampling settings a bit lower is tolerable, especially if the weights look OK. It should not be stuck at 0, i.e. all sampled plans are identical, and there shouldn't be any big spikes.. See this discussion on what the units of VI is or should be.

**Formal reference**: See SMC paper: VI “is the difference between the joint entropy and the mutual information of the distribution of population over the new districts relative to the existing districts.”

## Population deviation

Population deviation is the maximum percent deviation from the target district population, which equals the total population divided by the number of districts.

It is important to check that the enacted plan has a reasonable partisan deviation. It will be inflated if the state splits precincts, but if it is substantially higher, this is a signal to double check that it was added correctly to the `redist_map` object.


## Compactness

SMC nudges compactness as measured by the exponent of the log spanning tree compactness, which is highly correlated with edges removed and fairly well correlated with polsby popper.

### Polsby Popper
	
Polsby-Popper (PP) is measured for each district.
A greater value (which ranges 0-1) means a more compact district. PP is a ratio of the area over the perimeter squared; 1 represents a circle.
Ordered boxplots show the distribution of Polsby-Popper across districts. Ordered district 1 is the least compact district, whereas ordered district 8 is the most compact district.
 
**Check for**: A consistent discrepancy between the enacted plan and the simulations, _especially_ if the enacted plan is much more compact than the simulations. Also look for a lack of plan diversity in each ordered district. If all boxes are very tight (in terms of their y-range), this may concerning.

### Fraction (of edges) Kept

**Units**: Fraction (of edges) kept is measured for each plan.
 
**Definition**: Proportion of edges in the original adjacency graph that are not cut by a district line. In other words, the proportion of precinct boundaries that are same-district precincts.
A smaller value of this measure, i.e., more edges being cut, means the plan has less compact districts.
The two metrics are related. PP is more common, but FK is more robust to the inherent resolution of the map and the inherent geography of precincts.

### Bounding Box Reock

Bounding Box Reock (BBR) is measured for each district.
A greater value (which ranges 0-1) means a more compact district.
BBR is a ratio of the area of the district over the area of the minimum (fixed rotation) bounding box that contains the district; 1 represents a perfect rectangle.
Ordered boxplots show the distribution of Polsby-Popper across districts. Ordered district 1 is the least compact district, whereas higher numbers show more compact districts.

**Check for**: A consistent discrepancy between the enacted plan and the simulations, _especially_ if the enacted plan is much more compact than the simulations. Also look for a lack of plan diversity in each ordered district. If all boxes are very tight (in terms of their y-range), this may concerning.

## Administrative unit splits

### County and Municipal Splits

**Units**: Splits are defined for each plan.
 
**Interpretation**: The number of counties and municipalities which are not wholly contained in a single district.

### Total County and Municipal Splits

**Units**: Total splits are defined for each plan.

**Interpretation**: The number of unit-district pairs minus one, summed over all administrative units. For example, if a county is split between three districts, it contributes two to the total splits count.

## Minority VAP share
In cases where there is significant minority population in a state, we want to see that there is somewhat increased minority power in some districts. The goal is to avoid cracking (where all districts have relatively low minority VAP) or packing (where some districts have absurdly high minority VAP). Much of this comes into use when looking for states with existing majority minority districts. In those cases, we want to make sure that our simulated plans have (1) at least as many majority minority districts and (2) that those districts would perform.

## Example Plans
These provide an opportunity to check for obvious problems like discontiguities, and to ensure that the sampled plans look reasonable overall.

## Partisan Metrics
Internally, we do not check partisan metrics.




