-- 1. Dimensão de Prioridade e Regras de SLA (Metas em minutos úteis)
CREATE TABLE IF NOT EXISTS gold.dim_sla_policy (
    priority_name VARCHAR(50) PRIMARY KEY,
    sla_target_minutes NUMERIC NOT NULL,
    sla_target_hours NUMERIC NOT NULL,
    severity_order INT NOT NULL
);

INSERT INTO gold.dim_sla_policy (priority_name, sla_target_minutes, sla_target_hours, severity_order)
VALUES
    ('Highest', 120, 2.0, 1),   -- Crítica: 2h úteis
    ('High',    240, 4.0, 2),   -- Alta: 4h úteis
    ('Medium',  480, 8.0, 3),   -- Média: 8h úteis
    ('Low',     960, 16.0, 4),  -- Baixa: 16h úteis
    ('Lowest', 1440, 24.0, 5)   -- Muito Baixa: 24h úteis
ON CONFLICT (priority_name) DO NOTHING;

-- 2. Dimensão de Filas / Equipes de Atendimento
CREATE OR REPLACE VIEW gold.dim_queues AS
SELECT DISTINCT
    COALESCE(raw_payload->'fields'->'labels'->>0, 'Sem_Fila') AS queue_id,
    REPLACE(COALESCE(raw_payload->'fields'->'labels'->>0, 'Sem_Fila'), '_', ' ') AS queue_name,
    CASE
        WHEN COALESCE(raw_payload->'fields'->'labels'->>0, '') LIKE '%N1%' THEN 'Nível 1 - Triagem'
        WHEN COALESCE(raw_payload->'fields'->'labels'->>0, '') LIKE '%N2%' THEN 'Nível 2 - Especialistas'
        ELSE 'Nível 3 - Engenharia & Infra'
    END AS support_tier
FROM bronze.raw_jira_issues;

-- 3. Tabela Fato Principal: Consolidado de Chamados e Métricas de SLA
CREATE OR REPLACE VIEW gold.fact_tickets AS
WITH metrics_by_issue AS (
    SELECT
        issue_key,
        COUNT(*) AS total_transitions,
        SUM(duration_raw_minutes) AS total_raw_minutes,
        SUM(CASE WHEN is_sla_paused THEN duration_raw_minutes ELSE 0 END) AS paused_raw_minutes,
        SUM(CASE WHEN NOT is_sla_paused THEN duration_raw_minutes ELSE 0 END) AS active_raw_minutes,
        SUM(CASE WHEN NOT is_sla_paused THEN duration_business_minutes ELSE 0 END) AS net_business_minutes
    FROM silver.issue_status_history
    GROUP BY issue_key
)
SELECT
    b.issue_key,
    b.raw_payload->'fields'->>'summary' AS summary,
    b.raw_payload->'fields'->'issuetype'->>'name' AS issue_type,
    b.raw_payload->'fields'->'status'->>'name' AS current_status,
    COALESCE(b.raw_payload->'fields'->'priority'->>'name', 'Medium') AS priority_name,
    COALESCE(b.raw_payload->'fields'->'labels'->>0, 'Sem_Fila') AS queue_id,
    (b.raw_payload->'fields'->>'created')::TIMESTAMPTZ AS created_at,
    ((b.raw_payload->'fields'->>'created')::TIMESTAMPTZ AT TIME ZONE 'America/Sao_Paulo')::DATE AS created_date,
    CASE
        WHEN LOWER(b.raw_payload->'fields'->'status'->>'name') IN ('resolvido', 'resolved', 'done', 'concluído', 'closed') THEN TRUE
        ELSE FALSE
    END AS is_resolved,
    m.total_transitions,
    -- Flag de Ping-Pong (chamados que sofreram 3 ou mais repasses de status)
    CASE WHEN m.total_transitions >= 3 THEN TRUE ELSE FALSE END AS has_rework_pingpong,
    ROUND(m.total_raw_minutes, 2) AS total_raw_minutes,
    ROUND(m.paused_raw_minutes, 2) AS paused_raw_minutes,
    ROUND(m.active_raw_minutes, 2) AS active_raw_minutes,
    ROUND(m.net_business_minutes, 2) AS net_business_minutes,
    p.sla_target_minutes,
    -- Percentual de consumo do SLA (baseado no tempo ativo)
    ROUND((m.active_raw_minutes / NULLIF(p.sla_target_minutes, 0)) * 100, 1) AS sla_consumed_pct,
    -- Status de cumprimento do SLA
    CASE
        WHEN m.active_raw_minutes > p.sla_target_minutes THEN 'Estourado (Breached)'
        WHEN m.active_raw_minutes >= (p.sla_target_minutes * 0.8) THEN 'Em Risco (>80%)'
        ELSE 'Dentro do Prazo (OK)'
    END AS sla_status
FROM bronze.raw_jira_issues b
JOIN metrics_by_issue m ON b.issue_key = m.issue_key
LEFT JOIN gold.dim_sla_policy p
    ON COALESCE(b.raw_payload->'fields'->'priority'->>'name', 'Medium') = p.priority_name;

-- 4. Tabela Fato Detalhada: Gargalos por Etapa (para análise de onde o ticket trava)
CREATE OR REPLACE VIEW gold.fact_stage_bottlenecks AS
SELECT
    h.issue_key,
    COALESCE(b.raw_payload->'fields'->'labels'->>0, 'Sem_Fila') AS queue_id,
    h.step_order,
    h.status_name,
    h.is_sla_paused,
    h.is_current_status,
    h.duration_raw_minutes,
    h.duration_business_minutes
FROM silver.issue_status_history h
JOIN bronze.raw_jira_issues b ON h.issue_key = b.issue_key;