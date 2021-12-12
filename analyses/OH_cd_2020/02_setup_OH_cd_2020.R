###############################################################################
# Set up redistricting simulation for `OH_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OH_cd_2020}")

tgt_pop <- sum(oh_shp$pop)/15

# follow split rules
oh_counties <- as_tibble(oh_shp) %>%
    group_by(county) %>%
    summarize(across(starts_with("pop"), sum),
        across(starts_with("cd_"), ~ n_distinct(.) > 1, .names = "split_{.col}")) %>%
    mutate(class_co = if_else(pop > tgt_pop, "more", "less")) %>%
    select(county, pop, class_co, starts_with("split_"))

oh_munis <- as_tibble(oh_shp) %>%
    left_join(select(oh_counties, county, class_co), by = "county") %>%
    group_by(county, muni) %>%
    summarize(across(starts_with("pop"), sum),
        across(starts_with("vap"), sum),
        class_co = class_co[1]) %>%
    group_by(county) %>%
    transmute(muni = muni,
        class_muni = if_else(class_co == "more",
            case_when(pop == max(pop) & pop > 100e3 & pop < tgt_pop ~ "B(4)(b)",
                pop >= tgt_pop ~ "B(4)(a)",
                TRUE ~ "none"),
            "none")
    )

oh_shp_map <- oh_shp %>%
    left_join(select(oh_counties, -pop), by = "county") %>%
    left_join(oh_munis, by = c("muni", "county"))

map <- redist_map(oh_shp_map, pop_tol = 0.005, total_pop = pop,
    existing_plan = cd_2020, adj = oh_shp_map$adj) %>%
    suppressWarnings() %>%
    mutate(merge_unit = case_when(!split_cd_2020 ~ county,
        class_muni == "B(4)(b)" ~ muni,
        TRUE ~ as.character(1:n())))

map_2020 <- map %>%
    st_drop_geometry() %>%
    group_by(merge_unit, county, cd_2020) %>%
    summarize(across(matches("(pop|vap)"), sum),
        muni = muni[1],
        class_co = class_co[1],
        class_muni = class_muni[1]) %>%
    ungroup() %>%
    mutate(split_unit = if_else(class_muni == "B(4)(a)", muni, county))


# Add an analysis name attribute
attr(map, "analysis_name") <- "OH_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OH_2020/OH_cd_2020_map.rds", compress = "xz")
cli_process_done()
