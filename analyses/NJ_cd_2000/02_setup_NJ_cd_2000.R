###############################################################################
# Set up redistricting simulation for `NJ_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NJ_cd_2000}")

map <- redist_map(nj_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = nj_shp$adj)

# Pseudo-county
map <- map %>%
  mutate(
    pseudo_county = pick_county_muni(
      map,
      counties = county,   
      munis    = muni,     
      pop_muni = get_target(map)
    )
  )

# Add an analysis name attribute
attr(map, "analysis_name") <- "NJ_2000"

map$state <- "NJ"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NJ_2000/NJ_cd_2000_map.rds", compress = "xz")
cli_process_done()

# Define helper function before it is called
check_valid <- function(pref_n, plans_matrix) {
  
  pref_sep <- data.frame(unit = 1, geometry = sf::st_cast(pref_n[1, ]$geometry, "POLYGON"))
  
  for (i in 2:nrow(pref_n))
  {
    pref_sep <- rbind(pref_sep, data.frame(unit = i, geometry = sf::st_cast(pref_n[i, ]$geometry, "POLYGON")))
  }
  
  pref_sep <- sf::st_as_sf(pref_sep)
  pref_sep_adj <- redist::redist.adjacency(pref_sep)
  
  mainland <- pref_sep[which(unlist(lapply(pref_sep_adj, length)) > 0), ]
  mainland_adj <- redist::redist.adjacency(mainland)
  mainland$component <- geomander::check_contiguity(adj = mainland_adj)$component
  
  checks <- vector(length = ncol(plans_matrix))
  mainland_plans <- plans_matrix[mainland$unit, ]
  
  for (k in 1:ncol(plans_matrix))
  {

    checks[k] <- max(check_contiguity(mainland_adj, mainland_plans[, k])$component) == 1
  }
  
  return(checks)
  
}
