-- 2. View Silver: Reconstrução cronológica de cada etapa/status por chamado
CREATE OR REPLACE VIEW silver.issue_status_history AS
WITH raw_transitions AS (
    -- Extrai cada mudança de status registrada no changelog do JSONB
    SELECT
        b.issue_key,
        (b.raw_payload->'fields'->>'created')::TIMESTAMPTZ AS issue_created_at,
        (h->>'created')::TIMESTAMPTZ AS transition_at,
        item->>'fromString' AS from_status,
        item->>'toString' AS to_status
    FROM bronze.raw_jira_issues b,
         jsonb_array_elements(b.raw_payload->'changelog'->'histories') h,
         jsonb_array_elements(h->'items') item
    WHERE item->>'field' = 'status'
),
initial_state AS (
    -- Reconstrói o primeiro status do chamado (no momento da abertura)
    SELECT DISTINCT ON (b.issue_key)
        b.issue_key,
        (b.raw_payload->'fields'->>'created')::TIMESTAMPTZ AS entered_at,
        COALESCE(rt.from_status, b.raw_payload->'fields'->'status'->>'name') AS status_name,
        0 AS step_order
    FROM bronze.raw_jira_issues b
    LEFT JOIN raw_transitions rt ON b.issue_key = rt.issue_key
    ORDER BY b.issue_key, rt.transition_at ASC
),
subsequent_states AS (
    -- Cada transição subsequente
    SELECT
        issue_key,
        transition_at AS entered_at,
        to_status AS status_name,
        ROW_NUMBER() OVER (PARTITION BY issue_key ORDER BY transition_at ASC) AS step_order
    FROM raw_transitions
),
unified_timeline AS (
    SELECT * FROM initial_state
    UNION ALL
    SELECT * FROM subsequent_states
),
calculated_durations AS (
    SELECT
        issue_key,
        step_order,
        status_name,
        entered_at,
        -- Se não houve próxima transição, usa NOW() para calcular o tempo parado até agora
        COALESCE(
            LEAD(entered_at) OVER (PARTITION BY issue_key ORDER BY step_order),
            NOW()
        ) AS exited_at,
        CASE 
            WHEN LEAD(entered_at) OVER (PARTITION BY issue_key ORDER BY step_order) IS NULL THEN TRUE
            ELSE FALSE
        END AS is_current_status
    FROM unified_timeline
)
SELECT
    issue_key,
    step_order,
    status_name,
    entered_at,
    exited_at,
    is_current_status,
    -- Classifica se o status pausa o relógio do SLA
    CASE 
        WHEN LOWER(status_name) IN ('pending', 'aguardando cliente', 'waiting for customer') THEN TRUE
        ELSE FALSE
    END AS is_sla_paused,
    -- Duração corrida total em minutos
    ROUND(EXTRACT(EPOCH FROM (exited_at - entered_at)) / 60.0, 2) AS duration_raw_minutes,
    -- Duração em minutos úteis (Seg-Sex, 08h-18h)
    silver.calc_business_minutes(entered_at, exited_at) AS duration_business_minutes
FROM calculated_durations;