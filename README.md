# Indicadores Econômicos

## Introdução

O projeto Indicadores Econômicos tem como alvo central construir um ambiente integrado de coleta, tratamento, análise e visualização de dados socioeconômicos do Brasil, a fim de trazer praticidade na obtenção de tais variáveis, além de gerar evidências empíricas para pesquisas em economia aplicada e políticas públicas. Reunindo diferentes fontes oficiais de dados — como RAIS, PNADC, Atlas do Estado Brasileiro, Ipea Data, Banco Central e SIDRA/IBGE —, o projeto organiza informações de mercado de trabalho, setor público, condições socioeconômicas da população e indicadores macroeconômicos em um conjunto de scripts em R.

Cada componente do projeto cumpre um papel complementar. O módulo baseado na RAIS investiga a estrutura ocupacional de Minas Gerais, analisando padrões de remuneração e desigualdades salariais a partir de recortes como sexo, cor, escolaridade e setor de atividade, além de empregar métodos econométricos como a decomposição de Oaxaca para compreender diferenças salariais. Já a etapa com dados do Atlas do Estado Brasileiro explora a evolução da remuneração média no setor público, permitindo comparações entre poderes, esferas federativas e grupos demográficos ao longo do tempo.

A análise com microdados da PNADC aprofunda a investigação sobre os determinantes salariais das mulheres no Sudeste brasileiro, aplicando técnicas de regressão linear e testes econométricos para avaliar o impacto de variáveis como escolaridade, idade, cor, jornada e tipo de vínculo sobre a renda. Por fim, a integração de dados do Banco Central, Ipea e IBGE traz ao projeto uma dimensão macroeconômica, ao reunir séries históricas de taxa Selic, saldo do Novo Caged e IPCA — indicadores essenciais para compreender o ambiente econômico e contextualizar as dinâmicas observadas no mercado de trabalho.

Ao consolidar essas diferentes frentes analíticas em um único repositório, o projeto não apenas oferece um panorama abrangente do mercado de trabalho e da economia brasileira, mas também serve como base para estudos quantitativos, desenvolvimento de modelos econométricos e análises exploratórias em economia aplicada.

## Scripts

### dados_rais

O script `dado_rais.R` tem como objetivo construir um pipeline para coleta, tratamento, análise e modelagem de dados a partir da RAIS (Relação Anual de Informações Sociais), com foco no mercado de trabalho do estado de Minas Gerais no ano de 2024. Ele se insere no projeto como uma etapa para a análise da estrutura ocupacional mineira, permitindo investigar a distribuição dos vínculos trabalhistas e da remuneração média a partir de diferentes recortes — como sexo, cor, grau de instrução, setor de atividade e localização municipal — além de gerar insumos para análises econométricas, como a decomposição de Oaxaca.

A primeira parte é dedicada à coleta dos dados, realizada por meio do pacote `basedosdados`, que fornece acesso direto aos microdados públicos da RAIS, disponibilizados pelo Ministério do Trabalho e Emprego. A consulta, em SQL, extrai variáveis essenciais ao estudo, como identificador municipal, idade, sexo, raça/cor, grau de instrução, subsetor da atividade econômica e remuneração média. Também é coletado o dicionário de variáveis da RAIS, utilizado posteriormente para auxiliar no entendimento e na manipulação dos dados.

Na sequência, o script realiza um processo de tratamento e limpeza dos dados. São removidos outliers das variáveis de idade e remuneração, de modo a reduzir a influência de valores extremos. Variáveis são renomeadas para facilitar a leitura e a interpretação dos resultados, e filtros são aplicados para remover observações inconsistentes ou não informadas. Em seguida, realiza a recodificação de variáveis categóricas. A variável de subsetor é agregada em três grandes setores econômicos — primário, secundário e terciário.

Após o tratamento dos dados, o script gera estatísticas descritivas e visualizações exploratórias que permitem analisar o mercado de trabalho mineiro. Utilizando o pacote `plotly`, são construídos gráficos interativos que mostram (i) a proporção de homens e mulheres por setor econômico, (ii) a distribuição racial entre setores e (iii) a remuneração média segmentada por sexo, cor e nível de instrução. Essas visualizações revelam padrões relevantes. Além disso, a análise espacial é incorporada por meio do pacote `geobr`, que fornece geometrias dos municípios de Minas Gerais. Com isso, o script calcula a remuneração média por município e gera um mapa que evidencia a distribuição geográfica dos salários no estado, permitindo identificar disparidades regionais — inclusive, observou-se maiores níveis de remuneração nas regiões Noroeste de Minas e Triângulo Mineiro.

Com o objetivo de preparar os dados para análises econométricas, o script ainda gera variáveis dummy. Essa transformação converte categorias em variáveis binárias, facilitando sua inclusão em modelos estatísticos. São geradas dummies para sexo, cor, níveis de instrução e setores econômicos.

A última etapa analisa a desigualdade salarial por meio da decomposição de Oaxaca-Blinder, técnica econométrica amplamente utilizada na literatura sobre mercado de trabalho. O modelo estima a diferença média de remuneração entre homens e mulheres, controlando por idade, escolaridade, cor e setor de atividade. Os resultados revelam que, em média, as mulheres recebem R\$258,76 a menos do que os homens, mesmo após o controle pelas variáveis explicativas. Aproximadamente 58% dessa diferença pode ser atribuída a características observáveis, enquanto os 42% restantes não são explicados pelo modelo, sugerindo a presença de fatores estruturais, como discriminação de gênero ou barreiras não mensuradas à inserção e progressão profissional.

### dados_aebdata

O script `dados_aebdata.R` tem como propósito coletar, organizar e analisar séries temporais relacionadas à remuneração média de vínculos no setor público brasileiro, utilizando dados oficiais disponibilizados pelo Atlas do Estado Brasileiro, uma iniciativa do Ipea (Instituto de Pesquisa Econômica Aplicada). Esses dados são acessados por meio do pacote `aebdata`, que facilita a extração direta de informações disponíveis.

A coleta de dados ocorre empregando `get_series(series_id = 94)` para importar especificamente as informações sobre a remuneração média de vínculos públicos, desagregadas por poder (Executivo, Legislativo e Judiciário), esfera federativa (federal, estadual e municipal) e sexo (masculino e feminino).

Após a coleta, os dados passam por uma etapa de tratamento e reestruturação. As variáveis são organizadas no formato longo para facilitar a análise e visualização, e rótulos mais intuitivos são atribuídos aos diferentes tipos de vínculos e esferas governamentais. Também é realizada a padronização das categorias de sexo e a remoção de valores ausentes, garantindo a integridade e a legibilidade do conjunto de dados. Essa manipulação possibilita uma exploração mais direta e comparativa dos padrões salariais entre diferentes grupos do funcionalismo público.

Na seção final, o script gera uma visualização interativa que mostra a evolução da remuneração média ao longo do tempo, discriminada por poder, nível federativo e sexo. O gráfico, construído com `ggplot2` e convertido em objeto interativo com `plotly`, permite identificar tendências, desigualdades e possíveis mudanças estruturais na remuneração do setor público brasileiro. A ferramenta de tooltip detalhada facilita a análise exploratória.

### dados_pnadc

O script `dados_pnadc.R` tem como finalidade coletar, organizar e analisar microdados da PNADC (Pesquisa Nacional por Amostra de Domicílios Contínua), pesquisa realizada pelo IBGE que fornece informações detalhadas sobre o mercado de trabalho e características socioeconômicas da população brasileira. Os dados são obtidos diretamente por meio do pacote `PNADcIBGE`, que permite baixar séries trimestrais ou anuais, especificando variáveis de interesse, além de definir o diretório para armazenamento local dos arquivos.

A coleta de dados é feita selecionando variáveis-chave, como sexo, idade, cor ou raça, escolaridade, setor de trabalho, horas trabalhadas, condição no domicílio e salários. Para o estudo em questão, foi utilizada a PNADC do 4º trimestre de 2024, com foco em mulheres da região Sudeste, na faixa etária de 16 a 65 anos.

Após a importação, os dados passam por tratamento e transformação. Dummies são criadas para indicadores como horas trabalhadas acima de 44 horas e trabalhadores autônomos, e novas variáveis são derivadas, como experiência ao quadrado. Observações com valores faltantes são removidas, garantindo integridade para análises econométricas subsequentes.

Em sequência, o script realiza modelagens de regressão linear múltipla ponderadas pelos pesos da pesquisa, avaliando o efeito de idade, escolaridade, experiência, cor, horas de trabalho e condição de autonomia sobre salários. Testes de hipótese, incluindo Breusch-Pagan, Breusch-Godfrey e Anderson-Darling, identificam heterocedasticidade, autocorrelação e desvios da normalidade nos resíduos, sendo corrigidos pelo estimador de Newey-West para garantir inferências confiáveis. Também são avaliadas possíveis multicolinearidades por meio do VIF.

Os resultados indicam que escolaridade e idade têm efeito positivo sobre salários, enquanto ser trabalhador autônomo impacta negativamente. A cor ou raça evidencia desigualdades salariais, com mulheres brancas recebendo remunerações maiores. Horas trabalhadas acima da jornada padrão mostram associação positiva com salário, refletindo a relação direta entre tempo de trabalho e remuneração. Com isso, O script oferece uma análise dos determinantes do salário das mulheres na região Sudeste.

### dados_macroeconomicos

O script `dados_macroeconomicos.R` tem como intuito coletar, organizar e visualizar séries históricas de indicadores macroeconômicos relevantes para análise econômica. As fontes de dados utilizadas incluem o Banco Central do Brasil, o Ipea Data e o SIDRA/IBGE. Os dados são obtidos por meio dos pacotes `GetBCBData`, `ipeadatar` e `sidrar`, utilizando os códigos específicos de cada série.

No caso do Banco Central, o script coleta a série histórica da taxa Selic a partir do Time Series Management System. A série é estruturada e plotada de forma interativa utilizando `ggplot2` e `plotly`, facilitando a visualização da evolução da taxa de juros ao longo do tempo.

Para o Ipea Data, o script obtém a série do saldo registrado no Novo Caged, que indica o saldo líquido de empregos formais no Brasil. É possível listar todas as séries disponíveis, coletar a desejada e gerar gráficos interativos da série histórica, possibilitando análises de tendências e ciclos de, no caso, emprego formal.

Por último, coleta-se a série do IPCA (Índice Nacional de Preços ao Consumidor Amplo), o indicador de inflação, no SIDRA/IBGE. O script transforma a série em formato temporal, incluindo colunas de data apropriadas, e realiza a visualização interativa da evolução do índice, permitindo identificar períodos de maior ou menor variação de preços.

## Funções

### carrega_pacotes

A função `carrega_pacotes` carrega todos os pacotes essenciais para a execução do projeto `indicadores_economicos`.

### remove_outliers

A função `remove_outliers` identifica e remove outliers de um vetor numérico utilizando o método do IQR (Intervalo Interquartil) — técnica estatística para identificar valores discrepantes e medir a dispersão dos dados.
