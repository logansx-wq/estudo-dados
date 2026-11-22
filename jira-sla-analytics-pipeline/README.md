# Pipeline de Monitoramento Operacional & SLA (Jira Cloud API + Supabase)

Pipeline de dados construído para extrair histórico de chamados da API REST do Jira Cloud, armazenar dados semiestruturados em nuvem (PostgreSQL/Supabase) e aplicar regras complexas de negócio e governança de SLA utilizando **Arquitetura Medalhão (Bronze, Silver, Gold)**.

## Problema de Negócio
Em operações de suporte e sistemas, o tempo corrido entre a abertura e o encerramento de um chamado não reflete a eficiência real da equipe. Este estudo resolve três "dores" de gestão:
1. **Expurgo de Pausas:** Desconta o tempo em que o ticket ficou aguardando retorno do cliente (`Pending` / `Aguardando cliente`).
2. **Calendário Corporativo:** Contabiliza apenas minutos úteis (segunda a sexta-feira, das 08h às 18h, fuso `America/Sao_Paulo`).
3. **Detecção de Gargalos e Retrabalho:** Reconstrói a timeline de transições (`changelog`) para identificar filas onde o chamado trava e casos de *ping-pong* (3 ou mais repasses).

## Arquitetura da Solução

```text
[Jira Cloud REST API v3] 
       │  (GET /search/jql + expand=changelog + paginação nextPageToken)
       ▼
[Python Ingestion (extract_bronze.py)] 
       │  (Carga idempotente via UPSERT / psycopg2)
       ▼
[Supabase / PostgreSQL na Nuvem]
  ├── Camada Bronze (bronze.raw_jira_issues) ──► Armazenamento bruto em JSONB + índice GIN
  ├── Camada Silver (silver.issue_status_history) ──► Unpivot de JSON, Window Functions (LEAD/ROW_NUMBER) e função PL/pgSQL de horas úteis
  └── Camada Gold (gold.fact_tickets, dim_queues, dim_sla_policy) ──► Star Schema pronto para consumo analítico

```
# Tecnologias Utilizadas
Linguagem & Ingestão: Python 3 (requests, psycopg2, python-dotenv)

Banco de Dados na Nuvem: PostgreSQL (Supabase)

Modelagem & SQL Avançado: JSONB, índices GIN, CTEs, Window Functions (LEAD, ROW_NUMBER), funções PL/pgSQL e modelagem dimensional (Star Schema).

Estrutura do Repositório
```text
Plaintext
├── .env.example                # Modelo de variáveis de ambiente
├── .gitignore                  # Proteção de credenciais e ambiente virtual
├── requirements.txt            # Dependências do projeto
├── README.md                   # Documentação técnica
├── src/
│   ├── seed_jira.py            # Popula instância Jira Cloud via API (POST) simulando ciclo de vida
│   └── extract_bronze.py       # Extrai chamados com changelog (GET) e realiza UPSERT no Supabase
└── sql/
    ├── 01_ddl_bronze.sql       # Criação dos schemas e tabela JSONB na camada Bronze
    ├── 02_silver_logs.sql      # Função de minutos úteis e reconstrução de timeline (Silver)
    └── 03_gold_star_schema.sql # Views e tabelas dimensionais de SLA e gargalos (Gold)
```

## Como Executar o Projeto
Clone o repositório e crie um ambiente virtual:

```Bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
.\venv\Scripts\Activate.ps1  # Windows PowerShell
pip install -r requirements.txt
```
Renomeie .env.example para .env e preencha suas credenciais do Jira Cloud e Supabase.
<img width="673" height="237" alt="image" src="https://github.com/user-attachments/assets/557cac9e-97be-49f3-a2ab-1148429f5404" />
<img width="761" height="198" alt="image" src="https://github.com/user-attachments/assets/5c6139d9-f35b-4db1-908e-0855f47fb83f" />

Execute os scripts da pasta sql/ em ordem sequencial (01 a 03) no SQL Editor do Supabase.
<img width="642" height="139" alt="image" src="https://github.com/user-attachments/assets/bf5006b2-0a13-4af0-a87e-16185271df7e" />

Execute a extração para popular a camada Bronze:

```Bash
python src/extract_bronze.py
```

