-- 1. Criação dos schemas da Arquitetura Medalhão
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- 2. Tabela Bronze: armazena o JSON bruto retornado pela API do Jira
CREATE TABLE IF NOT EXISTS bronze.raw_jira_issues (
    issue_key VARCHAR(30) PRIMARY KEY,
    raw_payload JSONB NOT NULL,
    jira_updated_at TIMESTAMPTZ NOT NULL,
    ingested_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Índice GIN para acelerar consultas futuras dentro das chaves do JSONB
CREATE INDEX IF NOT EXISTS idx_raw_jira_payload 
ON bronze.raw_jira_issues USING GIN (raw_payload);