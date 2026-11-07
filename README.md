# SESHRRM

**Spatially Explicit Sequoiadendron Hydro-Refugia and Recruitment Model**

SESHRRM aims to 


|Script|Function|
|---|---|
|`01_DEM_processing.R`|depression breaching, FD8 flow accumulation, slope, TWI|
|`02_LiDAR_processing.R`|multi-tile collation, stem identification, keeps stems 70 to 100m tall, TWI buffering|
|`03_fire_return_processing.R`|derives near-site historic fire return interval from study multivariable dataset|
|`04_growth_simulation.R`|floor cell growth simulation, parameterised by tall stem proximity (light) and TWI|
|`05_descriptive_statistics.R`|slope, spearman, linear and quadratic models, crown-area sensitivity|
|`06_figure_creation.R`|whole site, sub-sites, growth curve|


