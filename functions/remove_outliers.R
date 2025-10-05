#' @name remove_outliers
#' @description Identifica e remove outliers de um vetor numérico utilizando o 
#' método do IQR.

remove_outliers <- function(x) {
  
  # 1) Identificando e removendo outliers
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR_val <- Q3 - Q1
  limite_inferior <- Q1 - 1.5 * IQR_val
  limite_superior <- Q3 + 1.5 * IQR_val
  x >= limite_inferior & x <= limite_superior
  
}