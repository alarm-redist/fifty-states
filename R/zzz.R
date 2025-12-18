.onLoad <- function(libname, pkgname) {
  options(
    tinytiger.use_cache = TRUE,
    baf.use_cache = TRUE
  )
  invisible(NULL)
}
