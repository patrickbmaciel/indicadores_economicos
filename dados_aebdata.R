# 0) Configurações iniciais -----------------------------------------------

# 0.1) Limpando RStudio
rm(list = ls())
cat("\014")

# 0.2) Importando funções
purrr::map(paste0("functions/", list.files("functions/", pattern = ".R$")), source)

# 1) Coleta de dados ------------------------------------------------------

# Importante: O pacote "aebdata" facilita o acesso aos dados publicados no Atlas
# do Estado Brasileiro, os quais podem ser importados por meio da função
# "get_series, ao passar o código da série de interesse no parâmetro "series_id". 
# Além disso, é pode-se obter informações sobre todas as bases disponíveis 
# através da função "list_series".

# 1.1) Obtendo lista de séries disponíveis, com os seus respectivos códigos
dados_aebdata <- aebdata::list_series()

# 1.2) Coletando séries temporais de remuneração no setor público
dados_remuneracao <- aebdata::get_series(series_id = 94)

# 2) Tratamento e plotagem ------------------------------------------------

# 2.1) Definindo rótulos
mapa_rotulos <- c(
  executivo = "Executivo", legislativo = "Legislativo", judiciario = "Judiciário",
  federal = "Federal", federal_civil = "Federal (civil)", federal_militar = "Federal (militar)",
  estadual = "Estadual", municipal = "Municipal", publico = "Público"
)

# 2.2) Transformando para long e limpando rótulos
dados_remuneracao_ajustado <- dados_remuneracao %>%
  dplyr::select(ano, starts_with("rem_media_vinculos_")) %>%
  tidyr::pivot_longer(-ano,
                    names_to = c("vinculo","sexo"),
                    names_pattern = "rem_media_vinculos_(.+)_(feminino|masculino)_controlado",
                    values_to = "valor") %>%
  dplyr::filter(!is.na(valor)) %>%
  dplyr::mutate(
    sexo = if_else(sexo == "feminino", "Feminino", "Masculino"),
    rotulo = ifelse(vinculo %in% names(mapa_rotulos), mapa_rotulos[vinculo],
                   str_to_title(str_replace_all(vinculo, "_", " ")))
  )

# 2.3) Definindo paleta: uma cor por rótulo
paleta <- setNames(colorRampPalette(RColorBrewer::brewer.pal(8, "Set1"))(n_distinct(dados_remuneracao_ajustado$rotulo)),
                sort(unique(dados_remuneracao_ajustado$rotulo)))

# 2.4) Construindo gráfico
grafico <- ggplot2::ggplot(dados_remuneracao_ajustado,
                           aes(x = ano, y = valor,
                               color = rotulo, linetype = sexo,
                               group = interaction(rotulo, sexo),
                               text = paste0("<b>", rotulo, "</b><br>Sexo: ", sexo,
                                             "<br>Ano: ", ano,
                                             "<br>Remuneração: R$ ", scales::comma(round(valor,2))))) +
  geom_line(size = 1) +
  scale_color_manual(values = paleta) +
  labs(title = "Remuneração Média de Vínculos Públicos nos Poderes e Níveis Federativos",
       x = "Ano", y = "Remuneração média (R$)") +
  theme_minimal() +
  theme(legend.position = "right")

# 2.5) Convertendo gráfico para plotly com tooltip (caixa de texto flutuante)
plotly::ggplotly(grafico, tooltip = "text") %>%
  layout(hovermode = "x unified", margin = list(l = 80, r = 220))
