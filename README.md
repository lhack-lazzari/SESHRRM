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
install.packages(c("sf", "terra", "whitebox", "tmap", "ggplot2", "ggnewscale", "ggspatial", "tidyverse", "lidR", "dplyr", "burnr"))
```

The C++ backend for `whitebox` must be initialised before running scripts.


## Ecohydrology

SESHRRM treats 2D surface topography as a baseline approximation of water availability. 

Mature sequoia can require up to 2m<sup>3</sup> per day during periods of maximum photosynthesis (Ambrose et al., 2016), and yet during these periods atmospherically sourced water supply is characteristically dry due to summer aridity. This, as suggested by Eppinger et al. (2026), points to significant sub surface deposits, utilised by mature sequoia.

The visual and statistical analysis reveals that while the spatial correlation between mature overstory height and surface moisture is weak (R<sup>2</sup> = 0.019), localised geomorphological flanks of high concentration TWI channels appear to support tall stem cohorts, indicating a decoupling between mature canopy structure and surface drainage accumulation layers.

This framework is built as an unvalidated exploratory scenario framework. It establishes a reproducible pipeline demonstrating the limitations of surface derived terrain covariates in potential areas of granitic bedrock fractures present, therefore necessitating a shift of focus towards critical-zone routing mechanisms defined by Hahm et al. (2019), and Eppinger et al. (2026), where ridge, and hillslope situated mature sequoia access deep weathered saprolitic moisture reserves (>2 m) below the reach of surface-based models. I acknowledge that simply height alone, as derived in the model, does not qualify overall morphological maturity.
