# 0) Configurações iniciais -----------------------------------------------

# 0.1) Limpando RStudio
rm(list = ls())
cat("\014")

# 0.2) Importando funções
purrr::map(paste0("functions/", list.files("functions/", pattern = ".R$")), source)

# 1) Coleta de dados ------------------------------------------------------

# Importante: A PNAD Contínua), realizada pelo IBGE, é a principal pesquisa 
# amostral sobre o mercado de trabalho e características socioeconômicas da 
# população brasileira. Disponível por meio do pacote "PNADcIBGE", ela permite 
# acessar e analisar microdados trimestrais e anuais.

# Conteúdo das variáveis:
# sexo = V2007
# escolaridade = VD3005
# setor de trabalho = VD4007 
# horas de trabalho = VD4014
# filtro ocupada = VD4002
# peso = V1028
# cor ou raça = V2010
# idade = V2009
# condição no domicílio = V2005

# 1.1) Definindo um vetor com os nomes das variáveis de interesse da PNAD 
# Contínua
variaveis <- c("UF", "V2007", "V2009", "V2010", "VD3005", "VD4014", 
               "VD4007", "V2005", "VD4002", "V1028", "VD4017")

# 1.2) Baixando a PNADC de 2024, referente ao 4º trimestre, além de especificar
# as variáveis desejadas
dados_pnad <- PNADcIBGE::get_pnadc(
  # Definindo o ano
  year = 2024, 
  # Definindo o trimestre
  quarter = 4, 
  # Definindo as variáveis a serem coletadas
  vars = variaveis, 
  # Definindo se os níveis das variáveis categóricas devam ser rotuladas de 
  # acordo com o dicionário da pesquisa
  labels = FALSE,
  # Definindo o endereço onde devem ser salvos os arquivos baixados
  savedir = paste0("C:/Users/", Sys.info()[["user"]], "/Downloads/"))

# 1.3) Reorganizando base de dados: selecionando e renomeando variáveis do dataset da 
# PNADC para um novo dataframe chamado "dados"
dados_pnad_select <- dados_pnad$variables %>% 
  dplyr::select(uf = UF, sexo = "V2007", salario = "VD4017", idade = "V2009",
                cor = "V2010", anos_estudo = "VD3005", horas_trabalho = "VD4014",
                setor_trabalho = "VD4007", condicao_domicilio = "V2005", 
                ocupado = "VD4002", peso = "V1028")

# 1.4) Realizando filtragem e transformações nos dados para gerar o dataframe
# final, chamado "dados_pnad_final"
dados_pnad_final <- dados_pnad_select %>% 
  # 1.4.1) Filtrando os dados:
  # - Estados da região Sudeste (UF: 31-MG, 32-ES, 33-RJ, 35-SP)
  # - Apenas mulheres (sexo = "2")
  # - Idade entre 16 e 65 anos
  # - Excluindo indivíduos que não declararam cor (cor != "9")
  dplyr::filter(uf == "31" | uf == "32" | uf == "33" | uf == "35",
                sexo == "2",
                idade >= 16 & idade <= 65,
                cor != "9") %>% 
  # 1.4.2) Modificando e criando novas variáveis
  dplyr::mutate(
    # Reclassificando a variável "cor" em uma dummy:
    # - "1" e "3" (branca e parda) serão convertidos para 1 (outras cores para 0)
    cor = ifelse(cor == "1" | cor == "3", 1, 0),
    # Convertendo "horas_trabalho" para numérico (caso ainda esteja em string ou fator)
    horas_trabalho = as.numeric(horas_trabalho),
    # Criando uma dummy para horas trabalhadas acima de 44 horas (1 = trabalha mais de 44h/semana)
    horas_trabalho = ifelse(horas_trabalho == "3" | horas_trabalho == "4" | horas_trabalho == "5", 1, 0),
    # Criando uma dummy para "autônomo" (1 = autônomo, que está na categoria 3 de setor_trabalho)
    autonomo = ifelse(setor_trabalho == "3", 1, 0),
    # Substituindo valores NA (não disponíveis) em "horas_trabalho" por 0
    horas_trabalho = ifelse(is.na(horas_trabalho), 0, horas_trabalho),
    # Substituindo valores NA em "autonomo" por 0
    autonomo = ifelse(is.na(autonomo), 0, autonomo),
    # Convertendo "anos_estudo" para numérico para realizar cálculos
    anos_estudo = as.numeric(anos_estudo),
    # Criando uma variável de experiência quadrática (experiência²)
    experiencia2 = (idade - anos_estudo - 6)^2,
    # Convertendo as variáveis dummies para tipo "character" para fins de consistência
    cor = as.character(cor),
    horas_trabalho = as.character(horas_trabalho),
    autonomo = as.character(autonomo)) %>% 
  # 1.4.3) Removendo a variável "setor_trabalho", pois já foi utilizada para criar a variável "autonomo"
  dplyr::select(-setor_trabalho) %>% 
  # 1.4.4) Removendo observações com valores faltantes (NA) em qualquer variável
  stats::na.omit()

# 2) Modelagem ------------------------------------------------------------

# 2.1) Ajustando o modelo de regressão linear múltipla
modelo <- stats::lm(
  # Variável dependente
  salario ~ 
    # Variáveis independentes
    idade + anos_estudo + experiencia2 +
    # Variáveis de controle
    cor + horas_trabalho + autonomo,
  data = dados_pnad_final, weights = peso)

# 2.2) Apresentando resumo estatístico do modelo
summary(modelo)

# 3) Testes de hipótese ---------------------------------------------------

# 3.1) Teste de homocedasticidade dos resíduos (Breusch-Pagan)
lmtest::bptest(modelo)

# 3.2) Teste de autocorrelação dos resíduos (Breusch-Godfrey)
lmtest::bgtest(modelo, order = 1)

# Considerações: Os resíduos do modelo apresentam heterocedasticidade, o que
# significa que a variância dos resíduos não é constante. Isso pode indicar que
# o modelo não está capturando completamente a estrutura dos dados ou que há 
# variáveis omitidas importantes.

# 3.3) Ajustando a matriz de covariância dos erros usando o estimador de
# Newey-West
vcov_nw <- sandwich::NeweyWest(modelo)
summary(modelo, vcov = vcov_nw)

# Considerações O ajuste de Newey-West é mais eficaz quando há uma forte 
# evidência de heterocedasticidade  ou autocorrelação. Se os erros padrão não 
# mudaram, isso sugere que o impacto dessas questões no modelo original pode
# não ter sido muito grande.

# 3.4) Calculado fator de inflação da variância (VIF) para verificar presença
# multicolinearidade
car::vif(modelo)

# 3.5) Verificação de normalidade dos resíduos
resid_mult <- modelo$residuals
hist(resid_mult, breaks = 50, main = "Histograma dos Resíduos", xlab = "Resíduos", col = "gray")

# 4) Novas modelagens -----------------------------------------------------

# 4.1) Modelo sem idade
modelo_sem_idade <- stats::lm(
  salario ~ 
    anos_estudo + experiencia2 +
    cor + horas_trabalho + autonomo,
  data = dados_pnad_final, weights = peso
)

# 4.1.1) Estatísticas
summary(modelo_sem_idade)

# 4.2) Modelo sem experência
modelo_sem_experiencia <- stats::lm(
  salario ~ 
    idade + anos_estudo +
    cor + horas_trabalho + autonomo,
  data = dados_pnad_final, weights = peso
)

# 4.2.1) Estatísticas
summary(modelo_sem_experiencia)

# 5) Novos testes de hipótese ---------------------------------------------

# 5.1) Teste de homocedasticidade dos resíduos (Breusch-Pagan)
bptest(modelo_sem_experiencia)

# 5.2) Teste de autocorrelação dos resíduos (Breusch-Godfrey)
bgtest(modelo_sem_experiencia, order = 1)

# Considerações: Os testes realizados indicaram p-valores extremamente baixos, 
# o que leva à rejeição das hipóteses nulas de homocedasticidade e ausência de 
# autocorrelação. Assim, há fortes evidências de que os resíduos do modelo 
# apresentam heterocedasticidade, isto é, variância não constante, e também 
# autocorrelação, ou seja, dependência ao longo do tempo. Esses problemas 
# comprometem a eficiência das estimativas, podem gerar erros padrão 
# subestimados e, consequentemente, reduzir a confiabilidade dos intervalos de 
# confiança e dos testes de significância aplicados ao modelo.

# 5.3) Ajustando a matriz de covariância dos erros usando o estimador de 
# Newey-West
vcov_nw_sem_experiencia <- sandwich::NeweyWest(modelo_sem_experiencia)
summary(modelo_sem_experiencia, vcov = vcov_nw_sem_experiencia)

# 5.4) Calculando fator de inflação da variância (VIF) para verificar presença
# multicolinearidade
car::vif(modelo_sem_experiencia)

# 5.5) Verificação de normalidade dos resíduos
resid_mult <- modelo_sem_experiencia$residuals
hist(resid_mult, breaks = 50, main = "Histograma dos Resíduos", xlab = "Resíduos", col = "lightblue")

# 5.6) Teste de Anderson-Darling
ad.test(resid_mult)

# Considerações: O resultado do teste de Anderson-Darling sugere que os resíduos
# não seguem uma distribuição normal. No entanto, considerando o tamanho muito 
# grande da amostra, é importante interpretar esse resultado com cautela. 
# Pequenas violações da normalidade podem ser detectadas em amostras grandes, 
# mas isso não necessariamente implica em problemas graves para a modelagem.

# 6) Conclusão ------------------------------------------------------------

# O modelo econométrico foi inicialmente submetido a uma série de testes para 
# avaliar sua adequação. O teste de multicolinearidade indicou um alto grau de 
# correlação entre as variáveis de idade e experiência ao quadrado, o que levou 
# à exclusão desta última para permitir a realização de testes subsequentes. 

# Em seguida, aplicou-se o teste de homocedasticidade de Breusch-Pagan, que 
# revelou um P-valor extremamente baixo (< 2.2e-16), indicando heterocedasticidade 
# nos resíduos. Isso sugere que a variância dos erros não é constante ao longo das
# observações, podendo comprometer a eficiência das estimativas e a confiabilidade
# dos intervalos de confiança. O teste de autocorrelação de Breusch-Godfrey 
# confirmou a presença de autocorrelação nos resíduos, evidenciando que os erros 
# do modelo não são independentes e que os erros padrão podem estar subestimados, 
# afetando a significância estatística dos coeficientes. O teste de Anderson-Darling,
# por sua vez, mostrou que os resíduos não seguem uma distribuição normal, embora 
# a grande amostra utilizada minimize impactos graves sobre a modelagem.

# Diante  desses resultados, a matriz de covariância dos erros foi ajustada pelo 
# estimador de Newey-West, garantindo inferências estatísticas válidas e correção
# dos erros padrão das estimativas.

# Com o modelo ajustado, analisou-se o impacto das variáveis sobre os salários 
# das mulheres na região Sudeste. A escolaridade apresentou relação positiva, 
# corroborando a Teoria do Capital Humano de Schultz (1958) e estudos como Soares
# e Gonzaga (1997), que apontam que maiores níveis de instrução aumentam a 
# probabilidade de salários mais altos. A idade também teve efeito positivo sobre
# o salário, alinhando-se com evidências de que trabalhadores mais velhos tendem 
# a acumular experiência e valor agregado ao empregador, embora esse efeito seja
# menos pronunciado na ausência de aumento na escolaridade ou habilidades 
# específicas (Souza, 2020). Quanto à cor ou raça, a dummy mostrou que indivíduos
# brancos recebem salários superiores aos de negros, mesmo após controles para 
# idade, escolaridade e região, em linha com os achados de Campello (2021).

# A variável horas trabalhadas revelou que aqueles que cumprem jornadas de 40 horas
# ou mais tendem a ter remunerações mais elevadas, refletindo a relação direta 
# entre tempo de trabalho e salário, embora fatores como eficiência e qualidade 
# das horas também influenciem este efeito (Cunha, 2020). Por fim, o fato de ser 
# trabalhador autônomo mostrou impacto negativo sobre o salário, possivelmente 
# devido à incerteza e variabilidade nos rendimentos desses indivíduos, que 
# contrastam com a estabilidade dos salários dos empregados (Furrier, 2023).
