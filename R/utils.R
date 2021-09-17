#' Download a file
#'
#' Backend-agnostic (currently `httr`)
#'
#' @param url a URL
#' @param path a file path
#'
#' @returns the `httr` request
download = function(url, path) {
    dir = dirname(path)
    if (!dir.exists(dir)) dir.create(dir, recursive=TRUE)
    if (!file.exists(path))
        httr::GET(url = url, httr::write_disk(path))
    else
        list(status_code=200)
}

#' Download redistricting data file
#'
#' @param abbr the state to download
#' @param folder will be downloaded to `folder/{abbr}_2020_*.csv`
#' @param type either `vtd` or `block`, depending on availability at
#'   <https://github.com/alarm-redist/census-2020/tree/main/census-vest-2020>.
#' @param overwrite if TRUE, download even if a file exists
#'
#' @returns the path to file
#' @export
download_redistricting_file = function(abbr, folder, type="vtd", overwrite=FALSE) {
    abbr = tolower(abbr)
    url = str_glue("https://raw.githubusercontent.com/alarm-redist/census-2020/",
                   "main/census-vest-2020/{abbr}_2020_{type}.csv")
    path = paste0(folder, "/", basename(url))

    if (!file.exists(path) || overwrite) {
        resp = download(url, path)
        if (resp$status_code == "404")  {
            stop("No files available for ", abbr)
        }
    }
    path
}

#' Add precinct shapefile geometry to downloaded data
#'
#' @param data the output of e.g. [download_redistricting_file]
#'
#' @returns the joined data
#' @export
join_vtd_shapefile = function(data) {
    geom_d = PL94171::pl_get_vtd(data$state[1]) %>%
        select(GEOID20, area_land=ALAND20, area_water=AWATER20, geometry)
    left_join(data, geom_d, by="GEOID20") %>%
        sf::st_as_sf()
}
