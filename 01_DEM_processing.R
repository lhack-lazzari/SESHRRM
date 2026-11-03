# 01_DEM_processing: pre-processing and TWI creation

# 1. load packages ----
library(sf)
library(terra)
library(whitebox)
library(tmap)
library(ggplot2)

# shapefile and DEM are both NAD83 UTM zone 11N (EPSG:26911)

# 2. load DEM ----
dem <- rast("data/site1_redwood_mountain_grove/raw/DEM/USGS_1M_11_x32y407_CA_SierraNevada_B22_uncompressed.tif")

# 3. load site shapefile ----
redwood_polygon <- st_read("data/site1_redwood_mountain_grove/site1_redwood_mountain_grove.shp")

# 4. crop raw DEM to bounding box of site polygon ----
# contributing area buffer for TWI not needed due to specific site topography having a self contained hydro catchment area
dem_cropped <- crop(dem, vect(redwood_polygon))

# 5. export cropped DEM to local files ----
# (required as WhiteboxTools C++ back-end operates on file paths)
writeRaster(dem_cropped,
            "data/site1_redwood_mountain_grove/processed/dem/dem_redwood_mountain_grove_slope_target.tif",
            overwrite = TRUE)

# 6. hydrological pre-processing ----
# breaching optimization allows continuous flow paths using least-cost carving (Lindsay and Dhun, 2015)
wbt_breach_depressions_least_cost(
  dem      = "data/site1_redwood_mountain_grove/processed/dem/dem_redwood_mountain_grove_slope_target.tif",
  output   = "data/site1_redwood_mountain_grove/processed/dem/dem_redwood_mountain_grove_breached.tif",
  dist     = 10,
  max_cost = NULL
)

# 7. dispersive contributing area ----
# fd8 flow routing disperses accumulated surface moisture across up to 8 neighboring cells
wbt_fd8_flow_accumulation(
  dem      = "data/site1_redwood_mountain_grove/processed/dem/dem_redwood_mountain_grove_breached.tif",
  output   = "data/site1_redwood_mountain_grove/processed/hydrology/flow_accum.tif",
  out_type = "Specific Contributing Area",
  exponent = 1.1 # captures a diffusive hillslope soil hydrology
)

# 8. calculate slope ----
# Whitebox wetness_index engine requires slope grids in degrees
wbt_slope(
  dem    = "data/site1_redwood_mountain_grove/processed/dem/dem_redwood_mountain_grove_breached.tif",
  output = "data/site1_redwood_mountain_grove/processed/hydrology/slope.tif",
  units  = "degrees"
)

# 9. topographic wetness index extraction ----
wbt_wetness_index(
  sca    = "data/site1_redwood_mountain_grove/processed/hydrology/flow_accum.tif",
  slope  = "data/site1_redwood_mountain_grove/processed/hydrology/slope.tif",
  output = "data/site1_redwood_mountain_grove/processed/hydrology/twi.tif"
)

# 10. continuous grid cap ----
twi_raw <- rast("data/site1_redwood_mountain_grove/processed/hydrology/twi.tif")
# limit channel saturation - cap twi above 25
twi <- twi_raw
twi[twi > 25] <- NA
writeRaster(twi, "data/site1_redwood_mountain_grove/processed/hydrology/twi_filtered.tif", overwrite = TRUE)


# 11. ploting TWI  ----
plot(twi, main = "Site topographic wetness index", col = hcl.colors(100, "Blues", rev = TRUE))
