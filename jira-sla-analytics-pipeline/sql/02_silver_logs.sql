-- 1. Função para calcular minutos úteis entre duas datas (Seg-Sex, 08h às 18h, Horário de Brasília)
CREATE OR REPLACE FUNCTION silver.calc_business_minutes(start_ts TIMESTAMPTZ, end_ts TIMESTAMPTZ)
RETURNS NUMERIC AS $$
DECLARE
    total_mins NUMERIC := 0;
    curr_day DATE;
    end_day DATE;
    s_local TIMESTAMP;
    e_local TIMESTAMP;
    day_start TIMESTAMP;
    day_end TIMESTAMP;
    eff_start TIMESTAMP;
    eff_end TIMESTAMP;
BEGIN
    IF start_ts IS NULL OR end_ts IS NULL OR end_ts <= start_ts THEN
        RETURN 0;
    END IF;

    -- Converte UTC para fuso horário de São Paulo
    s_local := start_ts AT TIME ZONE 'America/Sao_Paulo';
    e_local := end_ts AT TIME ZONE 'America/Sao_Paulo';

    curr_day := s_local::DATE;
    end_day := e_local::DATE;

    WHILE curr_day <= end_day LOOP
        -- ISODOW: 1 = Segunda ... 5 = Sexta (ignora 6 = Sábado e 7 = Domingo)
        IF EXTRACT(ISODOW FROM curr_day) BETWEEN 1 AND 5 THEN
            day_start := curr_day + TIME '08:00:00';
            day_end   := curr_day + TIME '18:00:00';

            eff_start := GREATEST(s_local, day_start);
            eff_end   := LEAST(e_local, day_end);

            IF eff_end > eff_start THEN
                total_mins := total_mins + EXTRACT(EPOCH FROM (eff_end - eff_start)) / 60.0;
            END IF;
        END IF;
        curr_day := curr_day + 1;
    END LOOP;

    RETURN ROUND(total_mins, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

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
