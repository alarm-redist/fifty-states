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
    1. We will enforce an R code style guide, based on the tidyverse style guide.
    Run `enforce_style("WA", "cd", 2020)` (with your details) periodically to
    automatically format your code.
    1. Document your analysis in the provided documentation file, including
    decisions on how to incorporate constraints, data sources, and simulation
    techniques.
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
