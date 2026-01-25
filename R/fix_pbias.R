download_dataverse = function(slug, get_doc=FALSE) {
    doi <- "10.7910/DVN/SLCD3E"
    files <- dataverse::dataset_files(doi)
    file_names <- purrr::map_chr(files, function(x) x$label)

    if (!any(str_detect(file_names, slug))) stop("`", slug, "` not available yet.")

    load_file = function(suffix="stats.tab") {
        ext = strsplit(suffix, "\\.")[[1]][2]
        if (ext == "tab") ext = "csv"

        tf <- tempfile(fileext = paste0(".", ext))
        fname = paste0(slug, "_", suffix)
        idx = match(fname, file_names)
        if (is.na(idx)) cli::cli_abort("File {.file {fname}} doesn't exist on Dataverse.")

        url <- str_c("https://dataverse.harvard.edu/api/access/datafile/", files[[idx]]$dataFile$id)
        resp <- httr::GET(
            url,
            httr::add_headers("X-Dataverse-key"=Sys.getenv("DATAVERSE_KEY")),
            query=list(format="original")
        )

        httr::stop_for_status(resp, task = httr::content(resp)$message)
        writeBin(httr::content(resp, as="raw"), tf)

        if (ext == "rds") {
            out <- read_rds(tf)
            file.remove(tf)
            out
        } else if (ext == "csv") {
            out <- read_csv(tf, col_types=cols(draw="f", chain="i", district="i"),
                            trim_ws=TRUE, show_col_types=FALSE)
            file.remove(tf)
            out
        } else if (ext == "html") {
            out <- rvest::read_html(tf, encoding="utf-8")
            file.remove(tf)
            out
        } else {
            tf
        }
    }

    map = load_file("map.rds")
    plans = load_file("plans.rds")
    stats_file = str_sub(file_names[str_detect(file_names, paste0(slug, "_stats\\."))], -9)
    stats = load_file(stats_file)
    if (isTRUE(get_doc))
        doc = load_file("doc.html")
    else
        doc = NULL

    if (is.ordered(plans$district))
        plans$district = as.integer(as.character(plans$district))
    if (is.character(plans$draw))
        plans$draw = forcats::fct_inorder(plans$draw)
    if (!is.null(plans$pop_overlap))
        plans$pop_overlap = NULL

    list(map=map, plans=plans, stats=stats, doc=doc)
}

fix_state = function(state, type = "cd", year = 2020, wait = TRUE) {
    state <- str_to_upper(state)
    cli::cli_h1(state)
    year <- as.character(as.integer(year))
    slug <- str_glue("{state}_{type}_{year}")

    Sys.sleep(5)

    d = download_dataverse(slug)
    cli::cli_alert_success("Downloaded old files from Dataverse.")
    plans = d$plans
    map = d$map

    elecs <- select(as_tibble(map), contains("_dem_")) |>
        names() |>
        str_sub(1, 6) |>
        unique()

    elect_tb <- purrr::map_dfr(elecs, function(el) {
        vote_d = select(as_tibble(map),
                        starts_with(paste0(el, "_dem_")),
                        starts_with(paste0(el, "_rep_")))
        if (ncol(vote_d) != 2) return(tibble())
        dvote <- pull(vote_d, 1)
        rvote <- pull(vote_d, 2)

        plans |>
            mutate(pbias = partisan_metrics(map, "Bias", rvote, dvote)) |>
            as_tibble() |>
            group_by(draw) |>
            transmute(draw = draw,
                      district = district,
                      pbias = pbias[1])
    }) |>
        group_by(draw, district) |>
        summarize(pbias = mean(pbias))

    stats = d$stats |>
        select(-pbias) |>
        left_join(elect_tb, by=c("draw", "district")) |>
        relocate(pbias, .before=egap)
    cli::cli_alert_success("Updated summary statistics.")

    path_stage = file.path(tempdir(), slug)
    if (dir.exists(path_stage)) unlink(path_stage, recursive=TRUE)
    dir.create(path_stage)
    path_plans <- str_glue("{path_stage}/{slug}_plans.rds")
    path_stats <- str_glue("{path_stage}/{slug}_stats.csv")
    write_rds(plans, path_plans, compress="xz")
    stats |>
        mutate(across(where(is.numeric), format, digits = 4, scientific = FALSE)) |>
        write_csv(path_stats)

    readable <- paste(year, censable::match_name(state), "Congressional Districts")

    path_zip <- file.path(tempdir(), paste0(slug, ".zip"))
    if (file.exists(path_zip)) file.remove(path_zip)
    cur_dir <- setwd(dirname(path_zip))
    zip(path_zip, slug, extras=str_glue("-x {slug}/.DS_Store"))
    setwd(cur_dir)
    cli::cli_alert_success("Zipped new files.")

    dv_id <- "doi:10.7910/DVN/SLCD3E"
    dv_set = dataverse::get_dataset(dv_id)

    id_plans = dv_set$files$id[dv_set$files$filename == basename(path_plans)]
    id_stats = dv_set$files$id[dv_set$files$filename == basename(path_stats)]
    if (length(id_stats) == 0) {
        base = str_replace(basename(path_stats), "\\.csv", ".tab")
        id_stats = dv_set$files$id[dv_set$files$filename == base]
    }

    cmd = str_glue('dataverse::add_dataset_file("{path_zip}", dataset="{dv_id}", description="{readable}")')
    if (length(id_plans) > 0) {
        success = dataverse::delete_file(id_plans)
        if (!success) {
            Sys.sleep(10)
            success = dataverse::delete_file(id_plans)
        }
        if (!success) {
            cli::cli_abort(c("Plans not deleted successfully.",
                        ">"="Delete files manually. Then run
                        {.code {cmd}}"))
        }
    } else {
        cli::cli_abort(c("Plans not found.",
                    ">"="Delete files manually. Then run
                    {.code {cmd}}"))
    }
    Sys.sleep(7)
    if (length(id_stats) > 0) {
        success = dataverse::delete_file(id_stats)
        if (!success) {
            Sys.sleep(10)
            success = dataverse::delete_file(id_stats)
        }
        if (!success) {
            cli::cli_abort(c("Stats not deleted successfully.",
                        ">"="Delete files manually. Then run
                        {.code {cmd}}"))
        }
    } else {
        cli::cli_abort(c("Stats not found.",
                    ">"="Delete files manually. Then run
                    {.code {cmd}}"))
    }
    cli::cli_alert_success("Deleted old files.")

    dataverse::add_dataset_file(path_zip, dataset=dv_id, description=readable)
    cli::cli_alert_success("Uploaded new files.")

    if (isTRUE(wait)) {
        time = round(nrow(stats) / 750)
        Sys.sleep(time)

        cli::cli_alert_success("Waited {time}s for ingest.")
    }

    invisible(TRUE)
}


# map(state.abb, possibly(fix_state, FALSE, quiet=FALSE))
