# 05_descriptive_statistics: slope info and stem height against twi

# 1. slope across the site ----

# 1.1 load packages ----
library(terra)
library(sf)

# 1.2 load site shapefile ----
redwood_polygon <- st_read("data/site1_redwood_mountain_grove/site1_redwood_mountain_grove.shp")

# 1.3 load raster ----
# whitebox, in degrees
slope_rast <- rast("data/site1_redwood_mountain_grove/processed/hydrology/slope.tif")

# 1.4 extract slope values inside polygon ----
slope_values <- terra::extract(slope_rast, vect(redwood_polygon), summary = FALSE)

# 1.5 mean, maximum slope ----
avg_slope_degrees <- mean(slope_values$slope, na.rm = TRUE)
max_slope_degrees <- max(slope_values$slope, na.rm = TRUE)

# 1.6 print ----
# using 2d.p., printing to make observation simple
cat(sprintf("average landscape slope: %.2f degrees\n", avg_slope_degrees))
cat(sprintf("maximum landscape slope: %.2f degrees\n", max_slope_degrees))

# 2. large stem height against twi ----
# Z is height measure, twi_mean is mean twi within 20m of each stem

# 2.1 spearman rank correlation ----
# do taller stems usually sit on twi's grasp of wetter ground? exact FALSE as stems share same height, not allowing exact p
cor.test(large_stems$Z, large_stems$twi_mean, method = "spearman", exact = FALSE) |>
  print()

# 2.2 linear model of height against twi ----
# slope is meters of extra height per unit of twi, r squared is amount of variation in height that twi explains
summary(lm(Z ~ twi_mean, data = large_stems))

# 2.3 sample amount and range of twi----
nrow(large_stems)
summary(large_stems$twi_mean)

# 2.4 twi-only model with a squared term ----
# check relationship distribution, if the squared term is non significant, a straight line is appropriate
summary(lm(Z ~ twi_mean + I(twi_mean^2), data = large_stems))

# 2.5 crown area sensitivity ----
# segmentation can split large crowns into multiple, repeated spearman test with stems above a minimum crown area m^2 of 5, 10, 20
# if rho stays roughly the same, small fragments are not driving result 
sens <- do.call(rbind, lapply(c(5, 10, 20), function(min_area) {
  d  <- large_stems[large_stems$convhull_area >= min_area, ]
  ct <- cor.test(d$Z, d$twi_mean, method = "spearman", exact = FALSE)
  data.frame(min_crown_area_m2 = min_area, n = nrow(d), rho = round(unname(ct$estimate), 3), p = signif(ct$p.value, 3))
}))
sens
