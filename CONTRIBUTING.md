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
    1. Document your analysis in the provided documentation file, including
    decisions on how to incorporate constraints, data sources, and simulation
    techniques.
    1. Any data you need to import into your analysis should be added under `data-raw/`.
    1. Any data you create over the course of your analysis should go under `data-draft/`.
    1. No data in either folder should be added to the GitHub.
    1. Don't edit the file paths for the `redist_map`, `redist_plans`, and
    summary statistic outputs.
1. Completing your analysis:
    1. Make sure you have removed all `TODO` lines from the template code.
    1. Make sure your documentation is up-to-date and correct.
    1. Create a pull request on GitHub. The PR be based off of a provided template.
    1. As part of the PR template, you will paste in diagnostic plots.
    1. Tag the graduate student assigned to your state for review. If you are a
    graduate student, tag another.
    1. Update the [tracker](https://docs.google.com/spreadsheets/d/1k_tYLoE49W_DCK1tcWbouoYZFI9WD76oayEt5TOmJg4/edit#gid=453387933) 
    to "Draft".
1. Finalizing your analysis
    1. Once your PR has been signed off, it may be merged into the main branch.
    1. In the main branch, run `finalize_analysis("WA", "cd", 2020)` (with your
    details) to finalize your analysis. This will add your generated files to
    the repository.
    1. Update the [tracker](https://docs.google.com/spreadsheets/d/1k_tYLoE49W_DCK1tcWbouoYZFI9WD76oayEt5TOmJg4/edit#gid=453387933) 
    to "Validated".
    
