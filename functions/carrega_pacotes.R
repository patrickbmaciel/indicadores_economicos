#' @name carrega_pacotes_macroeconomicos
#' @description Carrega todos os pacotes essenciais para a execução do projeto.

# 1) Evidenciando os packages essenciais
pacotes <- c("tidyverse", "lubridate", "dplyr", "tidyr", "ggplot2", "plotly", 
             "scales", "RColorBrewer", "grDevices", "survey", "convey", "lmtest", "oaxaca",
             "sandwich", "car", "nortest", "geobr", "viridis", "sf", "ggspatial", 
             "GetBCBData", "ipeadatar", "sidrar", "PNADcIBGE")

# 2) Carregando todos os packages
sapply(pacotes, library, character.only = TRUE)
