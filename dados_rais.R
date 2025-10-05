# 0) Configurações iniciais -----------------------------------------------

# 0.1) Limpando RStudio
rm(list = ls())
cat("\014")

# 0.2) Importando funções
purrr::map(paste0("functions/", list.files("functions/", pattern = ".R$")), source)

# 0.3) Configurando projeto
basedosdados::set_billing_id("basedosdados-382820")

# 1) Coleta de dados ------------------------------------------------------

# 1.1) Construindo query
query <- "
    SELECT 
        id_municipio,
        idade,
        sexo, 
        raca_cor,
        grau_instrucao_apos_2005,
        subsetor_ibge,
        valor_remuneracao_media 
    FROM 
        `basedosdados.br_me_rais.microdados_vinculos` 
    WHERE 
        ano = 2024 AND sigla_uf = 'MG'
" 

# 1.2) Coletando dicionário para tratamento automatizado
dicionario <- basedosdados::read_sql("SELECT * FROM `basedosdados.br_me_rais.dicionario`")

# 1.3) Obtendo dados da RAIS
rais_mg_2024 <- basedosdados::read_sql(query)

# 1.4) Visualizando estrutura dos dados
glimpse(rais_mg_2024)

# 1.5) Visualizando resumo estatístico dos dados
summary(rais_mg_2024)

# 2) Tratamento de dados --------------------------------------------------

# 2.1) Transformando o dicionário em vetor

# 2.1.1) Grau de instrução
dic_instrucao <- dicionario %>%
  dplyr::filter(nome_coluna == "grau_instrucao_apos_2005") %>%
  dplyr::select(chave, valor) %>%
  dplyr::distinct() %>%
  tibble::deframe()

# 2.1.2) Subsetor
dic_subsetor <- dicionario %>%
  dplyr::filter(nome_coluna == "subsetor_ibge") %>%
  dplyr::select(chave, valor) %>%
  dplyr::distinct() %>%
  tibble::deframe()

# 2.2) Removendo outliers: idade e remuneração
rais_sem_outliers <- rais_mg_2024 %>%
  dplyr::filter(
    remove_outliers(idade),
    remove_outliers(valor_remuneracao_media)
  )

# 2.3) Realizando demais tratamentos importantes
rais_tratada <- rais_sem_outliers %>%
  # Renomeando variáveis
  dplyr::rename(
    cor = raca_cor,
    instrucao = grau_instrucao_apos_2005,
    setor = subsetor_ibge,
    remuneracao = valor_remuneracao_media
  ) %>% 
  # Filtrando dados
  dplyr::filter(
    sexo %in% c("1", "2"),
    cor %in% c("1", "2", "4", "6", "8"),
    instrucao != "-1" & instrucao != "99"
  ) %>%
  # Ajustando variáveis
  dplyr::mutate(
    sexo = ifelse(sexo == "1", "masculino", "feminino"),
    cor = ifelse(cor == "2", "branco", "nao_branco"),
    instrucao = dic_instrucao[instrucao],
    setor = dic_subsetor[setor],
    instrucao = case_when(
      instrucao %in% c("5.A CO FUND", "6. A 9. FUND", "ATE 5.A INC") ~ "fundamental_incompleto",
      instrucao == "FUND COMPL" ~ "fundamental",
      instrucao == "ANALFABETO" ~ "analfabeto",
      instrucao == "MEDIO COMPL" ~ "medio",
      instrucao == "MEDIO INCOMP" ~ "medio_incompleto",
      instrucao == "SUP. COMP" ~ "superior",
      instrucao == "SUP. INCOMP" ~ "superior_incompleto",
      instrucao == "MESTRADO" ~ "mestrado",
      instrucao == "DOUTORADO" ~ "doutorado",
      TRUE ~ "outro"
    ),
    setor = case_when(
      str_detect(str_to_lower(stringi::stri_trans_general(setor, "Latin-ASCII")),
                 "agricultura|silvicultur|criaca|extrativ|mineral") ~ "primario",
      str_detect(str_to_lower(stringi::stri_trans_general(setor, "Latin-ASCII")),
                 "produtos aliment|bebidas|alcool|textil|vestuario|tecidos|borracha|fumo|couro|peles|calcad|papel|papelao|grafica|editorial|quimic|farmaceut|veterinar|perfum|produtos minerais nao metalicos|metalurg|mecanica|material eletr|material de transporte|madeira|mobiliario|utilidade|construc") ~ "secundario",
      TRUE ~ "terciario"
    ))

# 2.4) Visualizando estrutura dos dados
glimpse(rais_tratada)

# 2.5) Analisando resumo estatístico dos dados
summary(rais_tratada)

# 2.6) Salvando base de dados
saveRDS(rais_tratada, paste0("C:/Users/", Sys.info()[["user"]], "/Downloads/rais_tratada.rds"))

# 3) Visualizações --------------------------------------------------------

# 3.0) Definindo paleta de cores
paleta_sexo <- c("masculino" = "#336ca5", "feminino" = "#e36f7f")
paleta_cor <- c("branco" = "#efdead", "nao_branco" = "#a49180")

# 3.1) Proporção de sexo por setor
rais_tratada %>%
  dplyr::group_by(setor, sexo) %>%
  dplyr::summarise(total = n(), .groups = "drop") %>%
  dplyr::group_by(setor) %>%
  dplyr::mutate(proporcao = total / sum(total)) %>%
  dplyr::mutate(
    porcentagem = round(proporcao * 100, 1),
    setor = factor(setor, levels = unique(setor))
  ) %>%
  plotly::plot_ly(
    x = ~proporcao,
    y = ~setor,
    color = ~sexo,
    colors = paleta_sexo,
    type = "bar",
    orientation = "h",
    text = ~paste0(porcentagem, "%"),
    textposition = "inside",
    hoverinfo = "text"
  ) %>%
  plotly::layout(
    title = "Proporção de mulheres e homens por setor",
    xaxis = list(title = "Proporção (%)"),
    yaxis = list(title = "Setor"),
    barmode = "stack"
  )

# 3.2) Proporção de cor por setor
rais_tratada %>%
  dplyr::group_by(setor, cor) %>%
  dplyr::summarise(total = n(), .groups = "drop") %>%
  dplyr::group_by(setor) %>%
  dplyr::mutate(proporcao = total / sum(total)) %>%
  dplyr::mutate(
    porcentagem = round(proporcao * 100, 1),
    setor = factor(setor, levels = unique(setor))
  ) %>%
  plotly::plot_ly(
    x = ~proporcao,
    y = ~setor,
    color = ~cor,
    colors = paleta_cor,
    type = "bar",
    orientation = "h",
    text = ~paste0(porcentagem, "%"),
    textposition = "inside",
    hoverinfo = "text"
  ) %>%
  plotly::layout(
    title = "Proporção de brancos e não brancos por setor",
    xaxis = list(title = "Proporção (%)"),
    yaxis = list(title = "Setor"),
    barmode = "stack"
  )

# 3.3) Remuneração média por setor e sexo
rais_tratada %>%
  dplyr::group_by(setor, sexo) %>%
  dplyr::summarise(rem_media = mean(remuneracao, na.rm = TRUE)) %>%
  plotly::plot_ly(
    y = ~reorder(setor, rem_media),
    x = ~rem_media,
    color = ~sexo,
    colors = paleta_sexo,
    type = "bar",
    orientation = "h",
    text = ~paste0("R$", round(rem_media, 2)),
    hoverinfo = "text"
  ) %>%
  plotly::layout(
    title = "Remuneração média por setor e sexo",
    xaxis = list(title = "Remuneração média (R$)"),
    yaxis = list(title = "Setor"),
    barmode = "group"
  )

# 3.4) Remuneração média por setor e cor
rais_tratada %>%
  dplyr::group_by(setor, cor) %>%
  dplyr::summarise(rem_media = mean(remuneracao, na.rm = TRUE)) %>%
  plotly::plot_ly(
    y = ~reorder(setor, rem_media),
    x = ~rem_media,
    color = ~cor,
    colors = paleta_cor,
    type = "bar",
    orientation = "h",
    text = ~paste0("R$", round(rem_media, 2)),
    hoverinfo = "text"
  ) %>%
  plotly::layout(
    title = "Remuneração média por setor e cor",
    xaxis = list(title = "Remuneração média (R$)"),
    yaxis = list(title = "Setor"),
    barmode = "group"
  )

# 3.5) Remuneração média por grau de instrução e sexo
rais_tratada %>%
  dplyr::group_by(instrucao, sexo) %>%
  dplyr::summarise(rem_media = mean(remuneracao, na.rm = TRUE)) %>%
  dplyr::mutate(instrucao = factor(instrucao, levels = unique(instrucao))) %>%
  plotly::plot_ly(
    x = ~instrucao,
    y = ~rem_media,
    color = ~sexo,
    colors = paleta_sexo,
    type = 'bar',
    text = ~paste0("R$", round(rem_media, 2)),
    hoverinfo = "text"
  ) %>%
  plotly::layout(
    title = "Remuneração média por grau de instrução e sexo",
    xaxis = list(title = "Grau de instrução"),
    yaxis = list(title = "Remuneração média (R$)"),
    barmode = "group"
  )

# 3.6) Remuneração média por grau de instrução e cor
rais_tratada %>%
  dplyr::group_by(instrucao, cor) %>%
  dplyr::summarise(rem_media = mean(remuneracao, na.rm = TRUE)) %>%
  plotly::plot_ly(
    x = ~instrucao,
    y = ~rem_media,
    color = ~cor,
    colors = paleta_cor,
    type = "bar",
    text = ~paste0("R$", round(rem_media, 2)),
    hoverinfo = "text"
  ) %>%
  plotly::layout(
    title = "Remuneração média por grau de instrução e cor",
    xaxis = list(title = "Grau de instrução"),
    yaxis = list(title = "Remuneração média (R$)"),
    barmode = "group"
  )

# 4) Análise regional -----------------------------------------------------

# 4.1) Agregando remuneração média por município
rais_muni <- rais_tratada %>%
  dplyr::mutate(
    id_municipio = as.integer(id_municipio),
  ) %>%
  dplyr::filter(!is.na(id_municipio)) %>%
  dplyr::group_by(id_municipio) %>%
  dplyr::summarise(
    mean_rem = mean(remuneracao, na.rm = TRUE)
  )

# 4.2) Obtendo dados geográficos dos municípios de MG
muni_mg <- geobr::read_municipality(code_muni = "MG", year = 2024)

# 4.3) Juntando dados
muni_mg <- muni_mg %>%
  dplyr::mutate(code_muni = as.integer(code_muni)) %>%
  dplyr::left_join(rais_muni, by = c("code_muni" = "id_municipio"))

# 4.4) Plotando gráfico
ggplot2::ggplot(muni_mg) +
  geom_sf(aes(fill = mean_rem_plot), color = "grey60", size = 0.05) +
  scale_fill_viridis_c(
    option = "magma",
    na.value = "grey95",
    direction = -1,
    labels = scales::dollar_format(prefix = "R$ ", decimal.mark = ","),
    name = "Remuneração média"
  ) +
  labs(
    title = "Remuneração média por município — MG"
  ) +
  # Incluindo rosa dos ventos (seta norte)
  ggspatial::annotation_north_arrow(
    location = "bl",
    which_north = "true",
    pad_x = unit(0.02, "npc"),
    pad_y = unit(0.02, "npc"),
    style = north_arrow_fancy_orienteering(
    line_col = "black",
    fill = c("white", "black")
    )
  ) +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(size = 14, face = "bold")
  )

# 5) Manipulações pré-modelagem -------------------------------------------

# 5.1) Gerando variáveis categóricas (dummies)
rais_dummies <- rais_tratada %>% 
  dplyr::rename(
    branco = cor
  ) %>% 
  dplyr::mutate(
    # Dummies de sexo e cor
    sexo = as.character(ifelse(sexo == "masculino", 1, 0)),
    branco = as.character(ifelse(branco == "branco", 1, 0)),
    # Dummies de instrucao
    medio = as.character(ifelse(instrucao == "medio", 1, 0)),
    fundamental = ifelse(instrucao == "fundamental", 1, 0),
    superior = ifelse(instrucao == "superior", 1, 0),
    medio_incompleto = ifelse(instrucao == "medio_incompleto", 1, 0),
    superior_incompleto = ifelse(instrucao == "superior_incompleto", 1, 0),
    fundamental_incompleto = ifelse(instrucao == "fundamental_incompleto", 1, 0),
    analfabeto = ifelse(instrucao == "analfabeto", 1, 0),
    doutorado = ifelse(instrucao == "doutorado", 1, 0),
    mestrado = ifelse(instrucao == "mestrado", 1, 0),
    # Dummies de setor
    primario = ifelse(setor == "primario", 1, 0),
    secundario = ifelse(setor == "secundario", 1, 0),
    terciario = ifelse(setor == "terciario", 1, 0),
    # Convertendo dummies
    across(
      # Mantendo estas como estão:
      .cols = -c(idade, remuneracao),
      # Convertendo as demais:
      # .fns  = as.character
      .fns  = as.factor
      )
    ) %>% 
  dplyr::select(
    -c(id_municipio, instrucao, setor)
  ) %>% 
  filter(!is.na(remuneracao), remuneracao > 0, !is.na(idade))

# 5.2) Visualizando estrutura dos dados
glimpse(rais_dummies)

# 5.3) Analisando resumo estatístico dos dados
summary(rais_dummies)

# 5.4) Salvando base de dados
saveRDS(rais_dummies, paste0("C:/Users/", Sys.info()[["user"]], "/Downloads/rais_dummies.rds"))

# 6) Decomposição de Oaxaca -----------------------------------------------

# 6.1) Estimando a decomposição
decomp <- oaxaca::oaxaca(remuneracao ~ 
                           # Setor
                           primario + secundario + terciario +
                           # Instrução
                           medio + fundamental + superior + medio_incompleto + superior_incompleto + 
                           fundamental_incompleto + analfabeto + mestrado + doutorado +
                           # Demais variáveis
                           idade + branco | sexo,
                         data = rais_dummies, 
                         R = NULL)

# 6.2) Definção dos grupos: o grupo A refere-se a mulher, isto é, quando a 
# dummy de sexo tem valor igual a zero
decomp$n

# 6.2) Diferenciação dos salários
decomp$y

# 6.3) Conclusão

# Em média, as mulheres recebem R$258,76 a menos do que os homens, mesmo
# controlando por idade, escolaridade, cor e setor de atividade.
# Parte dessa diferença pode ser explicada por características observáveis, 
# e o restante representa o diferencial “não explicado” — potencialmente 
# associado a discriminação de gênero ou outros fatores estruturais.

# Aproximadamente R$150 da diferença salarial (cerca de 58%) se deve a 
# diferenças em características observáveis, enquanto R$ 109 (42%) permanece 
# não explicado — podendo refletir desigualdade de tratamento entre gêneros 
# no mercado de trabalho.
