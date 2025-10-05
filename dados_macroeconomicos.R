# 0) Configurações iniciais -----------------------------------------------

# 0.1) Limpando RStudio
rm(list = ls())
cat("\014")

# 0.2) Removendo notação científica
options(scipen = 999)

# 0.3) Importando funções
purrr::map(paste0("functions/", list.files("functions/", pattern = ".R$")), source)

# 0.4) Definindo data atual
data_atual <- Sys.Date()

# 0.5) Definindo parâmetros para plotagem de gráficos
cor_serie <- "#2f2c79"
tamanho_serie <- 1
quebras_data <- "2 years"
rotulos_data <- "%Y"
tamanho_tema <- 14

# 1) Banco Central --------------------------------------------------------

# Importante: O Time Series Management System do Banco Central do Brasil, 
# disponível em https://www3.bcb.gov.br/sgspub, contém séries históricas,
# que podem ser coletadas diretamente do RStudio a partir do pacote "GetBCBData",
# passando o código da série desejada no parâmetro "id".

# 1.1) Coletando série temporal da taxa SELIC
dados_selic <- GetBCBData::gbcbd_get_series(
  id = 432,
  first.date = "2000-01-01",
  last.date = data_atual
)

# 1.2) Plotando série temporal da taxa SELIC
plotly::ggplotly(
  ggplot2::ggplot(dados_selic, aes(x = ref.date, y = value)) +
    geom_line(color = cor_serie, size = tamanho_serie) +
    labs(
      title = "Série Temporal da Taxa Selic",
      x = "Data",
      y = "Taxa Selic (%)",
    ) +
    scale_x_date(
      date_breaks = quebras_data, 
      date_labels = rotulos_data
    ) +
    theme_minimal(base_size = tamanho_tema)
)

# 2) Ipea Data ------------------------------------------------------------

# Importante: O Ipea Data, presente em https://www.ipeadata.gov.br/, possui
# séries históricas, que podem ser coletadas em R através do pacote "ipeadatar",
# passando o código da série desejada no parâmetro ""code. Além disso, é 
# possível obter informações sobre todas as bases disponíveis por meio da
# função "available_series".

# 2.1) Obtendo lista de séries disponíveis, com os seus respectivos códigos
dados_ipea <- ipeadatar::available_series()

# 2.2) Coletando série temporal do Caged
dados_caged <- ipeadatar::ipeadata(code = "CAGED12_SALDON12") 

# 2.3) Plotando série temporal do Caged
plotly::ggplotly(
  ggplot2::ggplot(dados_caged, aes(x = date, y = value)) +
    geom_line(color = cor_serie, size = tamanho_serie) +
    labs(
      title = "Saldo Registrado no Novo Caged - Série sem Ajuste",
      x = "Data",
      y = "Empregados (Saldo)",
    ) +
    scale_x_date(
      date_breaks = quebras_data, 
      date_labels = rotulos_data
    ) +
    theme_minimal(base_size = tamanho_tema)
)

# 3) IBGE (SIDRA) ---------------------------------------------------------

# Importante: O SIDRA do IBGE, disponível em https://sidra.ibge.gov.br/, contém 
# dados históricos, que podem ser obtidos diretamente do RStudio por meio do 
# pacote "sidrar", passando o código da série desejada no parâmetro "api". Aliás,
# o código a ser informado é copiado do link de compartilhamento, iniciando-se 
# do "/t/" até o final.

# 3.1) Registrando código obtido no site SIDRA referente à tabela 7060 (IPCA)
codigo_ipca <- "/t/7060/n1/all/v/63/p/all/c315/7169/d/v63%202"

# 3.2) Coletando série
dados_ipca <- sidrar::get_sidra(api = codigo_ipca)

# 3.3) Incluindo coluna de data
dados_ipca <- dados_ipca %>% 
  dplyr::mutate(data = lubridate::ymd(paste0(`Mês (Código)`, "01")))

# 2.3) Plotando série temporal do Caged
plotly::ggplotly(
  ggplot2::ggplot(dados_ipca, aes(x = data, y = Valor)) +
    geom_line(color = cor_serie, size = tamanho_serie) +
    labs(
      title = "IPCA - Índice Nacional de Preços ao Consumidor Amplo",
      x = "Data",
      y = "Variação (%)",
    ) +
    scale_x_date(
      date_breaks = quebras_data, 
      date_labels = rotulos_data
    ) +
    theme_minimal(base_size = tamanho_tema)
)
