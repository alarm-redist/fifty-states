# `analyses` README

The `analyses` folder contains all of the code to generate and validate the
redistricting simulations. Each subfolder is a standalone and self-contained
analysis.

To run an analysis, source the R scripts in the folder in numbered order.
This can be done programmatically by running `lapply(sort(Sys.glob("*.R")), source)` 
from the analysis folder.

