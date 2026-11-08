# SESHRRM

**Spatially Explicit Sequoiadendron Hydro-Refugia and Recruitment Model**

An exploratory model that attempts to test whether slope-forced surface hydrological routing is related to distribution of large giant sequoia stems at grove scale, and how such relationship interacts with juvenile recruitment.

The project maps 1,059 stems taller than 70 m from airborne LiDAR within a steep (>20°) study area along the boundaries of Whitaker's Forest, Kings Canyon National Park and Sequoia National Forest, CA. (work in progress, no field validation).

|Script|Function|
|---|---|
|`01_DEM_processing.R`|depression breaching, FD8 flow accumulation, slope, TWI|
|`02_LiDAR_processing.R`|multi-tile collation, stem identification, keeps stems 70 to 100m tall, TWI buffering|
|`03_fire_return_processing.R`|derives near-site historic fire return interval from study multivariable dataset|
|`04_growth_simulation.R`|floor cell growth simulation, parameterised by tall stem proximity (light) and TWI|
|`05_descriptive_statistics.R`|slope, spearman, linear and quadratic models, crown-area sensitivity|
|`06_figure_creation.R`|whole site, sub-sites, growth curve|


## Package Dependencies

Requires:

- library(sf)
- library(terra)
- library(whitebox)
- library(tmap)
- library(ggplot2)
- library(ggnewscale)
- library(ggspatial)
- library(tidyverse)
- library(lidR)
- library(dplyr)
- library(burnr)

```R
install.packages(c(sf, terra, whitebox, tmap, ggplot2, ggnewscale, ggspatial, tidyverse, lidR, dplyr, burnr))
```

The C++ backend for `whitebox` must be initialised before running scripts.
