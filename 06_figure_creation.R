# 06_figure_creation: whole site, sub-sites, model response


# 0.0 load packages ----
library(sf)
library(terra)

# 0.1 load inputs ----
redwood_polygon <- st_read("data/site1_redwood_mountain_grove/site1_redwood_mountain_grove.shp")
twi_rast        <- rast("data/site1_redwood_mountain_grove/processed/hydrology/twi_filtered.tif")
large_stems     <- st_read("data/site1_redwood_mountain_grove/processed/stems/large_stems.shp")

# polygon and stems must be same crs as TWI raster
redwood_polygon <- st_transform(redwood_polygon, crs(twi_rast))
large_stems     <- st_transform(large_stems, crs(twi_rast))

# 1.0 hillshade creation ----

# 1.1 load DEM ----
dem <- rast("data/site1_redwood_mountain_grove/processed/dem/dem_redwood_mountain_grove_breached.tif")

# 1.2 calculate slope and aspect ----
slope  <- terrain(dem, v = "slope", unit = "radians")
aspect <- terrain(dem, v = "aspect", unit = "radians")

# 1.3 generate hillshade (angle = sun elevation, direction = sun azimuth) ----
hillshade <- shade(slope, aspect, angle = 45, direction = 315)

# 1.4 convert to df ----
hillshade_df <- as.data.frame(hillshade, xy = TRUE)
colnames(hillshade_df)[3] <- "hillshade"

# 1.5 save ----
writeRaster(hillshade, 
            "data/site1_redwood_mountain_grove/processed/dem/redwood_mountain_grove_hillshade.tif",
            overwrite = TRUE)



# 2.0 fig 1: TWI stem correlation site overview ----

# 2.1 load packages ----
library(ggplot2)
library(sf)
library(terra)
library(ggnewscale)
library(ggspatial)

# 2.2 crop and mask rasters to the polygon ----
bbox <- st_bbox(redwood_polygon)
xmin <- bbox["xmin"]
ymin <- bbox["ymin"]

hillshade_raw <- shade(terrain(dem, v = "slope", unit = "radians"), terrain(dem, v = "aspect", unit = "radians"), angle = 45, direction = 315)
hillshade_masked <- mask(crop(hillshade_raw, redwood_polygon), redwood_polygon)
twi_masked <- mask(crop(twi_rast, redwood_polygon), redwood_polygon)

# 2.3 change to 0 origin ----
# so r doesnt crash about otherwise massive UTM coordinate offsets..
hillshade_shifted <- terra::shift(hillshade_masked, dx = -xmin, dy = -ymin)
twi_shifted <- terra::shift(twi_masked, dx = -xmin, dy = -ymin)

hillshade_df <- as.data.frame(hillshade_shifted, xy = TRUE)
colnames(hillshade_df)[3] <- "hillshade"

twi_df <- as.data.frame(twi_shifted, xy = TRUE)
colnames(twi_df)[3] <- "twi"

# 2.4 shift polygon geometry, local bounding box ----
poly_local <- redwood_polygon
st_geometry(poly_local) <- st_geometry(poly_local) - c(xmin, ymin)
poly_coords <- st_coordinates(poly_local)
poly_df <- data.frame(
  x = poly_coords[, "X"],
  y = poly_coords[, "Y"],
  group = poly_coords[, "L1"]
)

local_bbox <- st_bbox(poly_local)

# 2.5 keep only stems inside the polygon ----
plot_pts_sf <- large_stems
plot_pts_clipped <- st_filter(plot_pts_sf, redwood_polygon, .predicate = st_within)

pt_coords <- st_coordinates(plot_pts_clipped)
plot_pts_clipped$X_local <- pt_coords[, 1] - xmin
plot_pts_clipped$Y_local <- pt_coords[, 2] - ymin

plot_pts_df <- as.data.frame(plot_pts_clipped)

# 2.6 "landscape_plot" ----
landscape_plot <- ggplot() +
  
  # layer 1 - hillshade background
  geom_raster(data = hillshade_df, aes(x = x, y = y, fill = hillshade), alpha = 0.8) +
  scale_fill_gradient(low = "black", high = "white", guide = "none") +
  
  new_scale_fill() +
  
  # layer 2 - TWI with blues
  geom_raster(data = twi_df, aes(x = x, y = y, fill = twi), alpha = 0.55) +
  scale_fill_gradientn(
    colors = c("#f7fbff", "#deebf7", "#9ecae1", "#4292c6", "#08306b", "#04153a"),
    trans = "sqrt",
    breaks = c(0, 5, 10, 15), 
    name = "Landscape TWI", 
    na.value = "transparent"
  ) +
  
  # layer 3 - site boundary
  geom_polygon(data = poly_df, aes(x = x, y = y, group = group), fill = NA, color = "white", linewidth = 0.4, alpha = 0.7) +
  
  # layer 4 - tree stems clipped
  geom_point(data = plot_pts_df, aes(x = X_local, y = Y_local, size = Z, color = twi_mean), stroke = 0.3, alpha = 0.9) +
  scale_color_viridis_c(option = "plasma", name = "Root-Zone TWI\n(20m Buffer Mean)") +
  scale_size_continuous(range = c(1.5, 6), limits = c(70, 100), breaks = c(70, 80, 90), name = "Tree height (m)") +
  
  # north arrow
  annotation_north_arrow(
    location = "br", 
    which_north = "true",
    style = north_arrow_minimal(text_col = "black", line_col = "black"),
    width = unit(0.7, "cm"), 
    height = unit(0.7, "cm"),
    pad_x = unit(0.2, "cm"),
    pad_y = unit(0.4, "cm")
  ) +
  
  # crop to the site
  coord_fixed(
    ratio = 1, 
    xlim = c(local_bbox["xmin"], local_bbox["xmax"]), 
    ylim = c(local_bbox["ymin"], local_bbox["ymax"]), 
    expand = FALSE
  ) +
  
  labs(
    title = "Redwood Mountain Grove Tall Stems TWI Proximity", 
    subtitle = "Spatial distribution of stems >70m relative to topographic wetness", 
    x = "Plot width (m)", 
    y = "Plot length (m)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "gray30", size = 9),
    panel.grid.major = element_line(color = "black", linewidth = 0.15, linetype = "dashed"),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    legend.position = "right",
    legend.box = "vertical",
    legend.spacing.y = unit(1.0, "cm"),          
    legend.box.margin = margin(t = 40, b = 40, l = 5, r = 5), 
    legend.title = element_text(face = "bold", size = 9),
    legend.text = element_text(size = 8.5),
    axis.text = element_text(color = "black"),
    plot.margin = margin(t = 10, r = 15, b = 10, l = 10)
  )

# 2.7 save figure ----
ggsave(
  filename = "figures/twi_correlation/twi_largestem_site_map_final.png", 
  plot = landscape_plot, 
  width = 7.8,   
  height = 11, 
  dpi = 1000
)


# 3.0 sub_site_a ----

# 3.1 define window limits ----

xmin_zoom <- 200
xmax_zoom <- 800
ymin_zoom <- 1200
ymax_zoom <- 1800

sub_site_a <- landscape_plot +
  
  # 3.2 crop to window ----
  coord_fixed(ratio = 1, xlim = c(xmin_zoom, xmax_zoom), ylim = c(ymin_zoom, ymax_zoom), expand = FALSE) +
  
  # 3.3 relabel axes so they start at zero relative to the zoom window origin ----
  scale_x_continuous(
    labels = function(x) x - xmin_zoom,
    breaks = seq(xmin_zoom, xmax_zoom, by = 200)
  ) +
  scale_y_continuous(
    labels = function(y) y - ymin_zoom,
    breaks = seq(ymin_zoom, ymax_zoom, by = 200)
  ) +
  
  labs(
    title = "Redwood Mountain Grove: sub site a",
    subtitle = "High-confluence zone",
    x = "Plot width (m)", 
    y = "Plot length (m)"
  ) +
  
  # 3.4 north arrow  ----
  annotation_north_arrow(
    location = "br", 
    which_north = "true",
    style = north_arrow_minimal(text_col = "black", line_col = "black"),
    width = unit(0.7, "cm"), 
    height = unit(0.7, "cm"),
    pad_x = unit(0.2, "cm"),
    pad_y = unit(0.4, "cm")
  )

# 3.5 save figure ----
ggsave(
  filename = "figures/twi_correlation/twi_sub_site_a.png", 
  plot = sub_site_a, 
  width = 7.8,   
  height = 8, 
  dpi = 1000
)


# 4.0 sub_site_b ----

# 4.1 define window limits ----
xmin_zoom <- 500
xmax_zoom <- 1100
ymin_zoom <- 850
ymax_zoom <- 1450

sub_site_b <- landscape_plot +
  
  # 4.2 crop to window ----
  coord_fixed(ratio = 1, xlim = c(xmin_zoom, xmax_zoom), ylim = c(ymin_zoom, ymax_zoom), expand = FALSE) +
  
  # 4.3 relabel axes so they start at zero relative to the zoom window origin ----
  scale_x_continuous(
    labels = function(x) x - xmin_zoom,
    breaks = seq(xmin_zoom, xmax_zoom, by = 200)
  ) +
  scale_y_continuous(
    labels = function(y) y - ymin_zoom,
    breaks = seq(ymin_zoom, ymax_zoom, by = 200)
  ) +
  
  labs(
    title = "Redwood Mountain Grove: sub site b",
    subtitle = "Slope headwater",
    x = "Plot width (m)", 
    y = "Plot length (m)"
  ) +
  
  # 4.4 north arrow  ----
  annotation_north_arrow(
    location = "br", 
    which_north = "true",
    style = north_arrow_minimal(text_col = "black", line_col = "black"),
    width = unit(0.7, "cm"), 
    height = unit(0.7, "cm"),
    pad_x = unit(0.2, "cm"),
    pad_y = unit(0.4, "cm")
  )

# 4.5 save figure ----
ggsave(
  filename = "figures/twi_correlation/twi_sub_site_b.png", 
  plot = sub_site_b, 
  width = 7.8,   
  height = 8, 
  dpi = 1000
)


# 5.0 sub_site_c ----

# 5.1 define window limits ----
xmin_zoom <- 360
xmax_zoom <- 960
ymin_zoom <- 1950
ymax_zoom <- 2550

sub_site_c <- landscape_plot +
  # 5.2 crop to window ----
  coord_fixed(ratio = 1, xlim = c(xmin_zoom, xmax_zoom), ylim = c(ymin_zoom, ymax_zoom), expand = FALSE) +
  
  # 5.3 relabel axes so they start at zero relative to the zoom window origin ----
  scale_x_continuous(
    labels = function(x) x - xmin_zoom,
    breaks = seq(xmin_zoom, xmax_zoom, by = 200)
  ) +
  scale_y_continuous(
    labels = function(y) y - ymin_zoom,
    breaks = seq(ymin_zoom, ymax_zoom, by = 200)
  ) +
  
  labs(
    title = "Redwood Mountain Grove: sub site c",
    subtitle = "Interfluve ridge zone",
    x = "Plot width (m)", 
    y = "Plot length (m)"
  ) +
  
  # 5.4 north arrow  ----
  annotation_north_arrow(
    location = "br", 
    which_north = "true",
    style = north_arrow_minimal(text_col = "black", line_col = "black"),
    width = unit(0.7, "cm"), 
    height = unit(0.7, "cm"),
    pad_x = unit(0.2, "cm"),
    pad_y = unit(0.4, "cm")
  )

# 5.5 save figure ----
ggsave(
  filename = "figures/twi_correlation/twi_sub_site_c.png", 
  plot = sub_site_c, 
  width = 7.8,   
  height = 7.8, 
  dpi = 1000
)



# 6.0 escape probability under 3 different shapes of the twi response ----
