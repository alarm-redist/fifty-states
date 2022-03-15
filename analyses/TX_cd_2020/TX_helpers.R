rep_cols <- function(mat, n) {
    do.call("cbind", lapply(seq_len(ncol(mat)), \(x) rep_col(mat[, x], n)))
}

rep_col <- function(col, n) {
    matrix(rep(col, n), ncol = n, byrow = FALSE)
}
