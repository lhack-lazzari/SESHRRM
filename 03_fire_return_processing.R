# 03_fire_return_processing: combining multi-sample dataset into numeric vector intervals

# 1. load packages ----
library(burnr)

# 2. read raw fhx ----
fhx <- read_fhx("data/site1_redwood_mountain_grove/raw/fire_return/usbsg001.fhx")

# 3. create composite fire record ----
# (burnr default requires 25% of recording trees scarred for valid interval year)
comp <- composite(fhx)

# 4. create 200 year pre-suppression window ----
fire_years <- get_event_years(comp)[[1]]

fire_years <- fire_years[fire_years >= 1700 & fire_years < 1900]

# 5. fire return intervals ----
fri <- diff(fire_years)

# 6. save intervals ----
dir.create("data/site1_redwood_mountain_grove/processed/fire_return", recursive = TRUE, showWarnings = FALSE)

saveRDS(fri, "data/site1_redwood_mountain_grove/processed/fire_return/usbsg001_fri_1700_1899.rds")

# 7. dataset stats/info check ----
length(unique(fhx$series))   # number of trees in record

length(fire_years)           # number of fires

length(fri)                  # number of intervals

summary(fri) 
