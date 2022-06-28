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
        geom_sf(data = map_north %>% filter(get_plans_matrix(plans_north)[, i] == 6),
            fill = "black")
    # South
    ex_plots[[k]] <- redist.plot.plans(plans_south, draws = i, map_south) +
        geom_sf(data = map_south %>% filter(get_plans_matrix(plans_south)[, i] == 0),
            fill = "black")
    # Full
    ex_plots[[l]] <- redist.plot.plans(plans, draws = i, map)


    j <- j + 1
}

ggsave("data-raw/FL/example_plans.png", (
    (ex_plots[[4]] + ex_plots[[5]] + ex_plots[[6]])/
        (ex_plots[[1]] + ex_plots[[2]] + ex_plots[[3]])/
        (ex_plots[[7]] + ex_plots[[8]] + ex_plots[[9]])
), width = 20, height = 20)

## VAP charts
d1 <- redist.plot.distr_qtys(
    plans,
    vap_black/total_vap,
    color_thresh = NULL,
    color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        "#3D77BB",
        "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent Black by VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black")) +
    ggredist::theme_r21()

d2 <- redist.plot.distr_qtys(
    plans,
    vap_hisp/total_vap,
    color_thresh = NULL,
    color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        "#3D77BB",
        "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous("Percent Hispanic by VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black")) +
    ggredist::theme_r21()

d3 <-
    redist.plot.distr_qtys(
        plans,
        (vap_hisp + vap_black)/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
    scale_y_continuous("HVAP + BVAP / VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2020_prop = "black")) +
    ggredist::theme_r21()

ggsave(
    plot = d1/d2,
    filename = "data-raw/FL/vap_plots.png",
    height = 9,
    width = 9
)
ggsave(
    plot = d3,
    filename = "data-raw/FL/vap_sum_plots.png",
    height = 9,
    width = 9
)


# Minority opportunity district histograms
psum <- plans %>%
    group_by(draw) %>%
    mutate(vap_nonwhite = total_vap - vap_white) %>%
    summarise(
        all_hvap = sum((vap_hisp/total_vap) > 0.4),
        dem_hvap = sum((vap_hisp/total_vap) > 0.4 &
            (ndv > nrv)),
        rep_hvap = sum((vap_hisp/total_vap) > 0.4 &
            (nrv > ndv)),
        all_bvap_40 = sum((vap_black/total_vap) > 0.4),
        all_bvap_30 = sum((vap_black/total_vap) > 0.3),
        mmd_all = sum(vap_nonwhite/total_vap > 0.5),
        mmd_coalition = sum(((
            vap_hisp + vap_black
        )/total_vap) > 0.5)
    )


p1 <-
    redist.plot.hist(psum, mmd_coalition) + labs(x = "HVAP + BVAP > 0.5", y = NULL)
p2 <-
    redist.plot.hist(psum, all_hvap) + labs(x = "HVAP > 0.4", y = NULL)
p3 <-
    redist.plot.hist(psum, dem_hvap) + labs(x = "HVAP > 0.4 & Dem. > Rep.", y = NULL)
p4 <-
    redist.plot.hist(psum, rep_hvap) + labs(x = "HVAP > 0.4 & Dem. < Rep.", y = NULL)
p5 <-
    redist.plot.hist(psum, all_bvap_40) + labs(x = "BVAP > 0.4", y = NULL)
p6 <-
    redist.plot.hist(psum, all_bvap_30) + labs(x = "BVAP > 0.3", y = NULL)

ggsave("data-raw/FL/vap_histograms.png", p1/p2/p3/p4/p5/p6, height = 9)
