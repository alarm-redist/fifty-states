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
    plans,
    cvap_black/total_cvap,
    color_thresh = NULL,
    color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        "#3D77BB",
        "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent Black by CVAP") +
    labs(title = "TX Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black")) +
    ggredist::theme_r21()

d2 <- redist.plot.distr_qtys(
    plans,
    cvap_hisp/total_cvap,
    color_thresh = NULL,
    color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        "#3D77BB",
        "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent Hispanic by CVAP") +
    labs(title = "TX Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black")) +
    ggredist::theme_r21()

d3 <-
    redist.plot.distr_qtys(
        plans,
        (cvap_hisp + cvap_black)/total_cvap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
    scale_y_continuous("HCVAP + BCVAP / CVAP") +
    labs(title = "TX Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black")) +
    ggredist::theme_r21()

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

psum <- plans %>%
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

psum <- plans %>%
    group_by(draw) %>%
    mutate(cvap_nonwhite = total_cvap - cvap_white) %>%
    summarise(
        all_hcvap = sum((cvap_hisp/total_cvap) > 0.4),
        dem_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
                            (ndv > nrv)),
        rep_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
                            (nrv > ndv)),
        all_bcvap = sum((cvap_black/total_cvap) > 0.4),
        dem_bcvap = sum((cvap_black/total_cvap) > 0.4 &
                            (ndv > nrv)),
        rep_bcvap = sum((cvap_black/total_cvap) > 0.4 &
                            (nrv > ndv)),
        mmd_all = sum(cvap_nonwhite/total_cvap > 0.5),
        mmd_coalition = sum(((
            cvap_hisp + cvap_black
        )/total_cvap) > 0.5)
    )

plans %>%
    filter(draw == "cd_2020") %>%
    mutate(bvap_pct = cvap_black/total_cvap) %>%
    arrange(desc(bvap_pct)) %>%
    select(district, bvap_pct)

map <- map %>% mutate(bvap_pct = cvap_black/cvap)

p <- redist.plot.map(
    map,
    plan = cd_2020,
    zoom_to = map$cd_2020 %in% c(30, 9, 18),
    boundaries = FALSE,
    fill_label = bvap_pct
)
ggsave("bcvap_zoom.pdf", p)

p <- plans %>%
    group_by(draw) %>%
    mutate(cvap_nonwhite = total_cvap - cvap_white,
           cvap_nw_prop = cvap_nonwhite/total_cvap)  %>%
    redist.plot.distr_qtys(
        cvap_nw_prop,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
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
