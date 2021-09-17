# `R` README

The `R` folder contains common code for all analyses, as well as management
code for creating new analyses from templates.  These functions may be loaded
all at once by running `devtools::load_all(".")` in R (Ctrl+Shift+L in RStudio).
Template code for all analysis is in the `template/` subfolder. In template code,
keywords surrounded by backticks, like ```STATE```, will be automatically
filled in when the template is used.
