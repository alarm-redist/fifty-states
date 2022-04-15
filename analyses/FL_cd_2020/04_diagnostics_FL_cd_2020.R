library(ggplot2)

# Example plots by region
draws <- sample(1:5000, 3)
ex_plots <- list()
j <- 1
for (i in draws) {
    k <- j + 3
    l <- j + 6
    # North
    ex_plots[[j]] <- redist.plot.plans(plans_north, draws = i, map_north) +
        geom_sf(data = map_north %>% filter(get_plans_matrix(plans_north)[, i] == 0),
            fill = "black")
    # South
    ex_plots[[k]] <- redist.plot.plans(plans_south, draws = i, map_south) +
        geom_sf(data = map_south %>% filter(get_plans_matrix(plans_south)[, i] == 12),
            fill = "black")
    # Full
    ex_plots[[l]] <- redist.plot.plans(plans, draws = i, map)


    j <- j + 1
}

ggsave("data-raw/FL/example_plans.pdf", (
    (ex_plots[[4]] + ex_plots[[5]] + ex_plots[[6]])/
        (ex_plots[[1]] + ex_plots[[2]] + ex_plots[[3]])/
        (ex_plots[[7]] + ex_plots[[8]] + ex_plots[[9]])
), width = 20, height = 20)

## CVAP charts
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
    labs(title = "FL Proposed Plan versus Simulations") +
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
    labs(title = "FL Proposed Plan versus Simulations") +
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
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black")) +
    ggredist::theme_r21()

ggsave(
    plot = d1/d2,
    filename = "data-raw/FL/cvap_plots.pdf",
    height = 9,
    width = 9
)
ggsave(
    plot = d3,
    filename = "data-raw/FL/cvap_sum_plots.pdf",
    height = 9,
    width = 9
)


# Minority opportunity district histograms
psum <- plans %>%
    group_by(draw) %>%
    mutate(cvap_nonwhite = total_cvap - cvap_white) %>%
    summarise(
        all_hcvap = sum((cvap_hisp/total_cvap) > 0.4),
        dem_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
            (ndv > nrv)),
        rep_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
            (nrv > ndv)),
        all_bcvap_40 = sum((cvap_black/total_cvap) > 0.4),
        all_bcvap_30 = sum((cvap_black/total_cvap) > 0.3),
        mmd_all = sum(cvap_nonwhite/total_cvap > 0.5),
        mmd_coalition = sum(((
            cvap_hisp + cvap_black
        )/total_cvap) > 0.5)
    )


p1 <-
    redist.plot.hist(psum, mmd_coalition) + labs(x = "HCVAP + BCVAP > 0.5", y = NULL)
p2 <-
    redist.plot.hist(psum, all_hcvap) + labs(x = "HCVAP > 0.4", y = NULL)
p3 <-
    redist.plot.hist(psum, dem_hcvap) + labs(x = "HCVAP > 0.4 & Dem. > Rep.", y = NULL)
p4 <-
    redist.plot.hist(psum, rep_hcvap) + labs(x = "HCVAP > 0.4 & Dem. < Rep.", y = NULL)
p5 <-
    redist.plot.hist(psum, all_bcvap_40) + labs(x = "BCVAP > 0.4", y = NULL)
p6 <-
    redist.plot.hist(psum, all_bcvap_30) + labs(x = "BCVAP > 0.3", y = NULL)

ggsave("data-raw/FL/cvap_histograms.pdf", p1/p2/p3/p4/p5/p6, height = 9)
