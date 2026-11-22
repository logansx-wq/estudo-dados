<<<<<<< Updated upstream
# Pipeline ETL: Arquitetura Medalhão (litígio consumidores)

Este estudo demonstra a construção de um pipeline de dados end-to-end aplicando os conceitos da Arquitetura Medalhão (Bronze, Silver e Gold). O objetivo é simular o fluxo de ingestão, higienização e modelagem analítica de dados reais e despadronizados oriundos de litígios de consumo.

## Objetivo do estudo
=======
# Pipeline ETL: Arquitetura Medalhão (litígio entre consumidores)

Este estudo demonstra a construção de um pipeline de dados end-to-end aplicando os conceitos da Arquitetura Medalhão (Bronze, Silver e Gold). O objetivo é simular o fluxo de ingestão, higienização e modelagem analítica de dados reais e despadronizados oriundos de litígios de consumo.

## Objetivo do Projeto
>>>>>>> Stashed changes
Processar uma base de dados crua, aplicando regras de negócio e limpeza estrutural em Python, para finalmente disponibilizar a informação num Banco de Dados Relacional (SQL Server) modelado em Star Schema, pronto para consumo via ferramentas de Business Intelligence (Power BI).

## Arquitetura e Fluxo de Dados

O estudo está dividido em três camadas de maturidade de dados:

### Camada Bronze (Dados Brutos)
<img width="617" height="61" alt="image" src="https://github.com/user-attachments/assets/1c615638-e133-4b23-84d2-b9ca7a87cb97" />
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
* **Fonte:** Arquivo CSV simulando extrações de sistemas de atendimento ao consumidor.
* **Características:** Dados exatamente como vieram da fonte, contendo erros de tipagem, formatos de data inconsistentes, valores nulos e falta de padronização nas strings (nomes de empresas com diferentes grafias).

### Camada Silver (Limpeza e Padronização)
<img width="678" height="71" alt="image" src="https://github.com/user-attachments/assets/99546e5d-00c9-4bb0-97aa-dac07ab45f39" />
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
* **Ferramenta:** Python (Pandas).
* **Processamento:** 
  * Unificação de strings e remoção de espaços em branco (padronização de réus e estados).
  * Conversão de múltiplas estruturas de texto para o tipo nativo datetime.
  * Tratamento de valores nulos e isolamento de outliers lógicos (notas fora do escopo 1-5).
* **Saída:** Arquivo reclamacoes_silver.csv com integridade garantida.

### Camada Gold (Modelagem Analítica)
<img width="655" height="79" alt="image" src="https://github.com/user-attachments/assets/76dfaaf0-e04e-4b48-99db-d389d37f0695" />

* **Ferramenta:** SQL Server (T-SQL).
* **Processamento:** 
  * Importação dos dados limpos para uma área de Staging.
  * Criação de tabelas com chaves primárias sub-rogadas (Surrogate Keys).
  * Distribuição dos dados via INSERT INTO ... SELECT DISTINCT para popular as Tabelas Dimensão (dim_empresa, dim_problema, dim_status).
  * Cruzamento de IDs via LEFT JOIN para popular a Tabela Fato (fato_reclamacoes).
* **Saída:** Modelo Relacional em Star Schema otimizado para consultas analíticas.

## Estrutura do Repositório

```text
pipeline_medalhao_consumidor/
├── 01_bronze/
│   └── reclamacoes_raw.csv           # Base bruta com erros propositais
├── 02_silver/
│   ├── limpeza_pandas.ipynb          # Notebook de higienizacao
│   └── reclamacoes_silver.csv        # Base limpa gerada pelo Python
├── 03_gold/
│   ├── ddl_star_schema.sql           # Script de criacao (Fato e Dimensoes)
│   └── carga_dados_gold.sql          # Script de ETL (Staging para Star Schema)
└── README.md
```

# Como Reproduzir este Estudo
### Pré-requisitos
Python 3.x e extensão do Jupyter Notebook instalada no VS Code.

Bibliotecas Python: pandas, numpy.

Banco de Dados: SQL Server e a interface SQL Server Management Studio (SSMS).

### Passo 1: Preparação do Ambiente
Clone este repositório para sua máquina local:

```Bash
git clone [https://github.com/logansx-wq/estudo-dados.git](https://github.com/logansx-wq/estudo-dados.git)
```
Navegue até o diretório: pipeline_medalhao_consumidor.

Certifique-se de que o arquivo bruto reclamacoes_raw.csv está presente na pasta 01_bronze.

### Passo 2: Processamento da Camada Silver (Python/Pandas)
Abra a pasta 02_silver no VS Code.

Abra o arquivo limpeza_pandas.ipynb.

Execute as células do notebook sequencialmente. Este script fará a leitura do arquivo bruto, o tratamento de tipagem, a limpeza de nulos, a normalização de strings e resolverá problemas de codificação (UTF-8/Latin-1).
<img width="1199" height="575" alt="image" src="https://github.com/user-attachments/assets/a4e256e3-23fe-49c9-a933-fcac95b240a7" />


<img width="1199" height="575" alt="image" src="https://github.com/user-attachments/assets/a4e256e3-23fe-49c9-a933-fcac95b240a7" />


Confirme se o arquivo reclamacoes_silver.csv foi gerado com sucesso dentro da própria pasta 02_silver.
<img width="283" height="29" alt="image" src="https://github.com/user-attachments/assets/c8dec6cd-fc13-4af7-aff0-63f914662bd9" />

<img width="283" height="29" alt="image" src="https://github.com/user-attachments/assets/c8dec6cd-fc13-4af7-aff0-63f914662bd9" />

### Passo 3: Modelagem da Camada Gold (SQL Server)
Abra o SSMS e conecte-se ao seu servidor local.

Abra o script 03_gold/ddl_star_schema.sql e execute-o. Isso criará o banco de dados isolado ProjetoConsumidorGold e a estrutura relacional vazia (Tabelas Dimensão e Tabela Fato).
<img width="229" height="210" alt="image" src="https://github.com/user-attachments/assets/07550c4d-93c3-475d-b28b-4336ac5ade85" />

<img width="229" height="210" alt="image" src="https://github.com/user-attachments/assets/07550c4d-93c3-475d-b28b-4336ac5ade85" />

Importe os dados limpos para a área de transição (Staging):

No SSMS, clique com o botão direito no banco ProjetoConsumidorGold.

Acesse Tarefas > Importar Arquivo Simples...
<img width="657" height="303" alt="image" src="https://github.com/user-attachments/assets/29729eab-b366-4e8b-a602-7f70a94212d6" />


<img width="657" height="303" alt="image" src="https://github.com/user-attachments/assets/29729eab-b366-4e8b-a602-7f70a94212d6" />


Selecione o arquivo reclamacoes_silver.csv gerado no Passo 2.

Defina o nome da nova tabela como stg_reclamacoes e conclua a importação.
<img width="811" height="285" alt="image" src="https://github.com/user-attachments/assets/4e037710-48a4-4fd7-8d4f-fad220adf9be" />

<img width="811" height="285" alt="image" src="https://github.com/user-attachments/assets/4e037710-48a4-4fd7-8d4f-fad220adf9be" />

Abra e execute o script 03_gold/carga_dados_gold.sql. Este script lerá os dados da tabela de staging, isolará os cadastros únicos nas dimensões (gerando chaves sub-rogadas) e fará o cruzamento via JOIN para alimentar a tabela Fato.

Valide a modelagem executando uma consulta final:

```SQL
SELECT * FROM ProjetoConsumidorGold.dbo.fato_reclamacoes;
```
