bootLoaded = T
source("P:/alsallam/WAO/lib/general_functions.r")
options(scipen = 20)
lapply(c(
  'data.table',
  'RODBC',
  'magrittr',
  'tidyverse'
  ), require, character.only = T) #

#jsonlite, broom, RColorBrewer, ggplot2, sqldf, fgui, scales, gtools, gridExtra, lubridate,

#openxlsx, shape, RJSONIO

#if (!is.na(channel))
source("P:/alsallam/lib/login.r")
source("P:/alsallam/WAO/lib/ReadCodesInGP.r")
#source('P:/alsallam/WAO/lib/alluvial-master/R/alluvial.R')

