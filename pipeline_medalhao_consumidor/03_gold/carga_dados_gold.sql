USE ProjetoConsumidorGold;
GO

-- ==============================================================================
-- PASSO 1: Alimentar as Tabelas Dimensão com valores únicos (DISTINCT)
-- ==============================================================================

INSERT INTO dim_empresa (nome_empresa)
SELECT DISTINCT empresa 
FROM stg_reclamacoes
WHERE empresa IS NOT NULL;

INSERT INTO dim_problema (descricao_problema)
SELECT DISTINCT problema 
FROM stg_reclamacoes
WHERE problema IS NOT NULL;

INSERT INTO dim_status (status_resolucao)
SELECT DISTINCT status_resolucao 
FROM stg_reclamacoes
WHERE status_resolucao IS NOT NULL;

-- ==============================================================================
-- PASSO 2: Alimentar a Tabela Fato cruzando os IDs gerados (JOIN)
-- ==============================================================================

INSERT INTO fato_reclamacoes (
    id_chamado_origem, 
    sk_empresa, 
    sk_problema, 
    sk_status, 
    data_registro, 
    uf_ocorrencia, 
    nota_consumidor
)
SELECT 
    s.id_chamado,
    de.sk_empresa,
    dp.sk_problema,
    ds.sk_status,
    s.data_registro,
    s.uf,
    s.nota_consumidor
FROM stg_reclamacoes s
LEFT JOIN dim_empresa de ON s.empresa = de.nome_empresa
LEFT JOIN dim_problema dp ON s.problema = dp.descricao_problema
LEFT JOIN dim_status ds ON s.status_resolucao = ds.status_resolucao;
GO

-- ==============================================================================
-- PASSO 3: Validação
-- ==============================================================================
SELECT * FROM fato_reclamacoes;