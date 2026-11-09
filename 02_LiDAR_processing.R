# 02_LiDAR_processing: multi-tile LiDAR segmentation

# 1. load packages ----

library(tidyverse)
library(lidR)
library(sf)
library(terra)

# 2. load site shapefile ----
redwood_polygon <- st_read("data/site1_redwood_mountain_grove/site1_redwood_mountain_grove.shp")

# 3. load TWI raster ----
twi_rast <- rast("data/site1_redwood_mountain_grove/processed/hydrology/twi_filtered.tif")

# 4. list of all LAZ files ----
laz_files_list <- list.files(
  path       = "data/site1_redwood_mountain_grove/raw/LiDAR/", 
  pattern    = "\\.(las|laz)$", 
  full.names = TRUE
)
stems_by_tile <- list()

# 5. size measure ----
# i attempted to estimate dbh from lidar height with an allometric equation however could not find site specific ground truthed data
# tree height Z (m) is the size measure instead, a stand in for tree size and water demand
min_height <- 70      # stems taller than this are treated as large
max_height <- 100     # upper limit to reduce noise

# 6. process tiles sequentially ----
cat(length(laz_files_list), "tiles to process\n")

for (i in 1:length(laz_files_list)) {
  current_file <- laz_files_list[i]
  cat("tile", i, "of", length(laz_files_list), basename(current_file), "\n")
  
  # remove noise - class 7 = low noise (ground), class 18 = high noise (sky)
  las_raw <- readLAS(current_file, filter = "-drop_class 7 18")
  
  # polygon and tile need same crs
  if (st_crs(redwood_polygon) != st_crs(las_raw)) {
    redwood_polygon <- st_transform(redwood_polygon, crs = st_crs(las_raw))
  }
  
  # to skip tiles outside site polygon
  tile_box <- st_as_sfc(st_bbox(las_raw))
  tile_overlaps <- st_intersects(tile_box, redwood_polygon, sparse = FALSE)
  
  if (!tile_overlaps) {
    cat("tile is outside site polygon\n")
    next
  }
  
  # rm all points outside site polygon
  las <- clip_roi(las_raw, redwood_polygon)
  
  if (length(las@data$X) == 0) {
    cat("no points inside site polygon in tile\n")
    next
  }
  
# find ground points
  las  <- classify_ground(las, algorithm = pmf(ws = 5, th = 3))
# remove the ground
  nlas <- normalize_height(las, algorithm = tin())
  
# canopy height model
  chm   <- rasterize_canopy(nlas, res = 0.5, algorithm = p2r(subcircle = 0.2))
# point is a treetop if it is the highest point within a 5m wind
  topts <- locate_trees(nlas, lmf(ws = 5))
  
  if (is.null(topts) || nrow(topts) == 0) {
    cat("no tree tops detected in tile\n")
    next
  }
  
  nlas  <- segment_trees(nlas, dalponte2016(chm, topts))

  # filter stem height class
  metrics <- as.data.frame(tree_metrics(nlas, func = .stdtreemetrics)) %>%
    filter(Z > min_height & Z <= max_height)
  
  if (nrow(metrics) == 0) {
    cat("no trees above height threshold in tile\n")
    next
  }
  
  
  # marks stem position from canopy
  stem_base <- as.data.frame(filter_poi(nlas, treeID %in% metrics$treeID & Z < 2.0)@data) %>%
    group_by(treeID) %>%
    summarise(X = mean(X), Y = mean(Y)) %>%
    st_as_sf(coords = c("X", "Y"), crs = st_crs(las))
  
  tile_stems <- merge(stem_base, metrics, by = "treeID")
  stems_by_tile[[i]] <- tile_stems
  
  # free up memory
  rm(las_raw, las, nlas, chm, topts, metrics, stem_base, tile_stems)
  gc()
}

# 7. combine stems from all tiles and extract twi around each stem ----
clean_stems_list <- stems_by_tile %>% compact()
stem_data        <- do.call(rbind, clean_stems_list)
stem_data        <- st_transform(stem_data, crs = crs(twi_rast))

regional_buffers <- st_buffer(stem_data, dist = 20)
twi_values <- terra::extract(twi_rast, vect(regional_buffers), summary = FALSE)

twi_stats <- twi_values %>%
  group_by(ID) %>%
  summarise(twi_mean = mean(twi, na.rm = TRUE), twi_max = max(twi, na.rm = TRUE))

large_stems <- stem_data %>%
  mutate(ID = row_number()) %>%
  left_join(twi_stats, by = "ID") %>%
  filter(!is.na(twi_mean))

# 8. export the large stem data ----
stems_out <- large_stems[, c("treeID", "Z", "convhull_area", "twi_mean")]
names(stems_out)[names(stems_out) == "convhull_area"] <- "crown_m2"   # shapefile column names max 10 characters

dir.create("data/site1_redwood_mountain_grove/processed/stems", recursive = TRUE, showWarnings = FALSE)
st_write(stems_out, "data/site1_redwood_mountain_grove/processed/stems/large_stems.shp", delete_dsn = TRUE)

stem_rast <- terra::rasterize(vect(stems_out), twi_rast, field = "Z")
writeRaster(stem_rast, "data/site1_redwood_mountain_grove/processed/stems/large_stems_height.tif", overwrite = TRUE)
