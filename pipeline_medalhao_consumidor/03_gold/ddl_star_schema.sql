-- Criação do banco de dados isolado para o projeto
CREATE DATABASE ProjetoConsumidorGold;
GO

USE ProjetoConsumidorGold;
GO

-- ==============================================================================
-- 1. Criação das Tabelas Dimensão (Cadastros Únicos)
-- ==============================================================================

CREATE TABLE dim_empresa (
    sk_empresa INT IDENTITY(1,1) PRIMARY KEY,
    nome_empresa VARCHAR(100) NOT NULL
);
GO

CREATE TABLE dim_problema (
    sk_problema INT IDENTITY(1,1) PRIMARY KEY,
    descricao_problema VARCHAR(150) NOT NULL
);
GO

CREATE TABLE dim_status (
    sk_status INT IDENTITY(1,1) PRIMARY KEY,
    status_resolucao VARCHAR(50) NOT NULL
);
GO

-- ==============================================================================
-- 2. Criação da Tabela Fato (Eventos / Métricas)
-- ==============================================================================

CREATE TABLE fato_reclamacoes (
    sk_fato INT IDENTITY(1,1) PRIMARY KEY,
    id_chamado_origem INT NOT NULL,           -- Trazido da camada Bronze/Silver
    sk_empresa INT FOREIGN KEY REFERENCES dim_empresa(sk_empresa),
    sk_problema INT FOREIGN KEY REFERENCES dim_problema(sk_problema),
    sk_status INT FOREIGN KEY REFERENCES dim_status(sk_status),
    data_registro DATE NOT NULL,
    uf_ocorrencia VARCHAR(2),
    nota_consumidor FLOAT
);
GO