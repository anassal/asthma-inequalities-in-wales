source("P:/alsallam/WAO/lib/general_functions.r")
options(scipen = 20)
require(data.table)
require(RODBC)
require(magrittr)
require(tidyverse)
require(lubridate)

source("P:/alsallam/lib/login.r")
source("P:/alsallam/WAO/lib/ReadCodesInGP.r")
source("P:/alsallam/WAO/lib/gpact/R/gpact.4.2.r")

cpu_cluster = parallel::makeCluster(32)
