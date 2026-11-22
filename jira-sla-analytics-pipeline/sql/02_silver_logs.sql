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