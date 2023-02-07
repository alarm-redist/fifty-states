###############################################################################
# Simulate plans for `TX_cd_2020`
# © ALARM Project, February 2022
###############################################################################

library(patchwork)

i <- 25
p1 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[, i] == 0),
        fill = "black")
i <- 35
p2 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[, i] == 0),
        fill = "black")
i <- 45
p3 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[, i] == 0),
        fill = "black")
i <- 11
p4 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[, i] == 0),
        fill = "black")
i <- 8
p5 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[, i] == 0),
        fill = "black")
i <- 5
p6 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[, i] == 0),
        fill = "black")

ggsave("data-raw/houston.pdf", (p1 + p2 + p3)/(p4 + p5 + p6), width = 20, height = 20)

p <- redist.plot.plans(austin_plans, draws = c(10, 20, 30, 50), m2)
ggsave("data-raw/austin.pdf")

p <- redist.plot.plans(dallas_plans, draws = c(10, 20, 30, 50), m3)
ggsave("data-raw/dallas.pdf")

library(ggplot2)
library(patchwork)

## local results
d1 <- redist.plot.distr_qtys(
    plans_5k,
    cvap_black/total_cvap,
    color_thresh = NULL,
    color = ifelse(
        subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
        "#3D77BB",
        "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent Black by CVAP") +
    labs(title = "TX Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black"))

d2 <- redist.plot.distr_qtys(
    plans_5k,
    cvap_hisp/total_cvap,
    color_thresh = NULL,
    color = ifelse(
        subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
        "#3D77BB",
        "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent Hispanic by CVAP") +
    labs(title = "TX Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black"))

d3 <-
    redist.plot.distr_qtys(
        plans_5k,
        (cvap_hisp + cvap_black)/total_cvap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
    scale_y_continuous("HCVAP + BCVAP / CVAP") +
    labs(title = "TX Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black"))

ggsave(
    plot = d1/d2,
    filename = "data-raw/cvap_plots.pdf",
    height = 9,
    width = 9
)
ggsave(
    plot = d3,
    filename = "data-raw/cvap_sum_plots.pdf",
    height = 9,
    width = 9
)

psum <- plans_5k %>%
    group_by(draw) %>%
    summarise(
        all_hcvap = sum((cvap_hisp/total_cvap) > 0.4),
        dem_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
            (ndv > nrv)),
        rep_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
            (nrv > ndv))
    )

p1 <- redist.plot.hist(psum, all_hcvap)
p2 <- redist.plot.hist(psum, dem_hcvap)
p3 <- redist.plot.hist(psum, rep_hcvap)

ggsave("data-raw/hist.pdf", p1/p2/p3)

psum <- plans_5k %>%
    group_by(draw) %>%
    mutate(cvap_nonwhite = total_cvap - cvap_white) %>%
    summarise(
        all_hcvap = sum((cvap_hisp/total_cvap) > 0.4),
        dem_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
            (ndv > nrv)),
        rep_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
            (nrv > ndv)),
        all_bcvap = sum((cvap_black/total_cvap) > 0.35),
        dem_bcvap = sum((cvap_black/total_cvap) > 0.35 &
            (ndv > nrv)),
        rep_bcvap = sum((cvap_black/total_cvap) > 0.35 &
            (nrv > ndv)),
        mmd_all = sum(cvap_nonwhite/total_cvap > 0.5),
        mmd_coalition = sum(((
            cvap_hisp + cvap_black
        )/total_cvap) > 0.5)
    )

plans_5k %>%
    filter(draw == "cd_2010)") %>%
    mutate(bvap_pct = cvap_black/total_cvap) %>%
    arrange(desc(bvap_pct)) %>%
    select(district, bvap_pct)

map <- map %>% mutate(bvap_pct = cvap_black/cvap)

p <- redist.plot.map(
    map,
    plan = cd_2010,
    zoom_to = map$cd_2010 %in% c(30, 9, 18),
    boundaries = FALSE,
    fill_label = bvap_pct
)
ggsave("bcvap_zoom.pdf", p)

p <- plans_5k %>%
    group_by(draw) %>%
    mutate(cvap_nonwhite = total_cvap - cvap_white,
        cvap_nw_prop = cvap_nonwhite/total_cvap)  %>%
    redist.plot.distr_qtys(
        cvap_nw_prop,
        color = ifelse(
            subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        color_thresh = NULL
    ) +
    scale_y_continuous("Percent Non-White by CVAP") +
    labs(title = "TX Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black"))
ggsave("data-raw/qty_nonwhite.pdf", p, width = 9)

p0 <-
    redist.plot.hist(psum, mmd_all) + labs(x = "Nonwhite CVAP > 0.5", y = NULL)
p1 <-
    redist.plot.hist(psum, mmd_coalition) + labs(x = "HCVAP + BCVAP > 0.5", y = NULL)
p2 <-
    redist.plot.hist(psum, all_hcvap) + labs(x = "HCVAP > 0.4", y = NULL)
p3 <-
    redist.plot.hist(psum, dem_hcvap) + labs(x = "HCVAP > 0.4 & Dem. > Rep.", y = NULL)
p4 <-
    redist.plot.hist(psum, rep_hcvap) + labs(x = "HCVAP > 0.4 & Dem. < Rep.", y = NULL)
p5 <-
    redist.plot.hist(psum, all_bcvap) + labs(x = "BCVAP > 0.4", y = NULL)
p6 <-
    redist.plot.hist(psum, dem_bcvap) + labs(x = "BCVAP > 0.4 & Dem. > Rep.", y = NULL)

ggsave("data-raw/hist.pdf", p0/p1/p2/p3/p4/p5/p6, height = 9)

library(ggthemes)

# enacted districts + demographic stats
enacted <- plans %>% filter(draw == "cd_2010)")
enacted_map <- tx_shp %>%
    group_by(cd_2010) %>%
    summarise(geom = st_union(geometry),
        cvap_black = sum(cvap_black),
        pct_black = sum(cvap_black)/sum(cvap),
        cvap_hisp = sum(cvap_hisp),
        pct_hisp = sum(cvap_hisp)/sum(cvap),
        cvap_white = sum(cvap_white),
        cvap_nonwhite = sum(cvap) - sum(cvap_white),
        pct_nonwhite = cvap_nonwhite/sum(cvap),
        total_cvap = sum(cvap))

# districts of interest
districts <- c("2", "7", "9", "18", "22", "29", "14", "36", "8", "10")

# map of precincts
all_precincts <- tx_shp %>%
    mutate(pct_black = cvap_black/cvap,
        pct_hisp = cvap_hisp/cvap,
        pct_nonwhite = (cvap - cvap_white)/cvap)

precincts <- all_precincts %>%
    filter(cd_2010 %in% districts)

# map of specific enacted districts, racial heat map
enacted_map %>% filter(cd_2010 %in% districts) %>%
    mutate(prop_black = cvap_black/total_cvap,
        prop_hisp = cvap_hisp/total_cvap) %>%
    ggplot(aes(fill = prop_hisp)) +
    geom_sf() +
    scale_fill_viridis_c("% Hispanic (2010)",
        labels = scales::percent_format(accuracy = 1),
        direction = 1,
        limits = c(0, 1)) +
    geom_sf_label(aes(label = cd_2010),
        label.padding = unit(0.1, "lines"), size = 4, fill = "white") +
    theme_map() +
    theme(legend.position = "bottom")

# overlay districts on precincts
precincts %>% ggplot(aes(fill = pct_hisp)) +
    geom_sf() +
    scale_fill_viridis_c("% Hispanic (2010)",
        labels = scales::percent_format(accuracy = 1),
        direction = 1,
        limits = c(0, 1)) +
    geom_sf(data = enacted_map %>% filter(cd_2010 %in% districts),
        alpha = 0, linewidth = 0.5, color = "#ff7f00") +
    geom_sf_label(data = enacted_map %>% filter(cd_2010 %in% districts), aes(label = cd_2010),
        label.padding = unit(0.1, "lines"), size = 4, fill = "white") +
    theme_map() +
    theme(legend.position = "bottom")

# boxplot of black cvap percentage
p <- redist.plot.distr_qtys(
    plans,
    cvap_black/total_cvap,
    geom = "boxplot",
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent Black by CVAP") +
    labs(title = "TX Proposed Plan versus Simulations")

# boxplot of hispanic cvap percentage
p <- redist.plot.distr_qtys(
    plans,
    cvap_hisp/total_cvap,
    geom = "boxplot",
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent Hispanic by CVAP") +
    labs(title = "TX Proposed Plan versus Simulations")

# boxplot of hcvap + bcvap percentage
p <- redist.plot.distr_qtys(
    plans,
    (cvap_hisp + cvap_black)/total_cvap,
    geom = "boxplot",
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent HCVAP + BCVAP") +
    labs(title = "TX Proposed Plan versus Simulations")

# rank by bcvap and democratic
plans %>%
    group_by(draw) %>%
    mutate(bcvap = cvap_black/total_cvap, bcvap_rank = rank(bcvap)) %>%
    subset_sampled() %>%
    select(draw, district, bcvap, bcvap_rank, ndv, nrv) %>%
    mutate(dem = ndv > nrv) %>%
    group_by(bcvap_rank) %>%
    summarize(dem = mean(dem))

# rank by hispanic and republican
plans %>%
    group_by(draw) %>%
    mutate(hcvap = cvap_hisp/total_cvap, hcvap_rank = rank(hcvap)) %>%
    subset_sampled() %>%
    select(draw, district, hcvap, hcvap_rank, ndv, nrv) %>%
    mutate(rep = ndv < nrv) %>%
    group_by(hcvap_rank) %>%
    summarize(rep = mean(rep))

# simulated draws
shp <- tx_shp
shp$dist <- get_plans_matrix(plans)[, 5000]
shp_dist <- shp %>%
    group_by(dist) %>%
    summarize(
        geom = st_union(geometry),
        pct_hisp = sum(cvap_hisp)/sum(cvap),
        pct_black = sum(cvap_black)/sum(cvap),
        pct_nonwhite = (sum(cvap) - sum(cvap_white))/sum(cvap))
shp_dist_filter <- shp_dist %>%
    filter(dist %in% districts)
precincts %>% ggplot(aes(fill = pct_nonwhite)) +
    geom_sf() +
    scale_fill_viridis_c("% Black (2010)",
        labels = scales::percent_format(accuracy = 1),
        direction = 1,
        limits = c(0, 1)) +
    geom_sf(data = shp_dist_filter,
        alpha = 0, linewidth = 0.5, color = "#ff7f00") +
    geom_sf_label(data = shp_dist_filter, aes(label = dist),
        label.padding = unit(0.1, "lines"), size = 1, fill = "white") +
    theme_map() +
    theme(legend.position = "bottom")

# nonwhite percentage with enacted district overlay
all_precincts %>% ggplot(aes(fill = pct_nonwhite)) +
    geom_sf() +
    scale_fill_viridis_c("% Nonwhite (2010)",
        labels = scales::percent_format(accuracy = 1),
        direction = 1,
        limits = c(0, 1)) +
    geom_sf(data = enacted_map,
        alpha = 0, linewidth = 0.5, color = "#ff7f00") +
    geom_sf_label(data = enacted_map, aes(label = cd_2010),
        label.padding = unit(0.1, "lines"), size = 1, fill = "white") +
    theme_map() +
    theme(legend.position = "bottom")

# hcvap + bcvap percentage with enacted district overlay
all_precincts %>% ggplot(aes(fill = pct_black + pct_hisp)) +
    geom_sf() +
    scale_fill_viridis_c("% HCVAP + BCVAP (2010)",
        labels = scales::percent_format(accuracy = 1),
        direction = 1,
        limits = c(0, 1)) +
    geom_sf(data = enacted_map,
        alpha = 0, linewidth = 0.5, color = "#ff7f00") +
    geom_sf_label(data = enacted_map, aes(label = cd_2010),
        label.padding = unit(0.1, "lines"), size = 1, fill = "white") +
    theme_map() +
    theme(legend.position = "bottom")
