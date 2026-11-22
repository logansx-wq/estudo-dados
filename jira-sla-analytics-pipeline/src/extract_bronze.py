import os
import json
import requests
from requests.auth import HTTPBasicAuth
import psycopg2
from psycopg2.extras import Json
from dotenv import load_dotenv

load_dotenv(override=True)

JIRA_URL = os.getenv("JIRA_BASE_URL").rstrip("/")
JIRA_EMAIL = os.getenv("JIRA_EMAIL")
JIRA_TOKEN = os.getenv("JIRA_API_TOKEN")
PROJECT_KEY = os.getenv("JIRA_PROJECT_KEY")
SUPABASE_DB_URL = os.getenv("SUPABASE_DB_URL")

auth = HTTPBasicAuth(JIRA_EMAIL, JIRA_TOKEN)
headers = {"Accept": "application/json"}


def fetch_all_issues():
    """Extrai todos os chamados do projeto com changelog via paginação nextPageToken."""
    url = f"{JIRA_URL}/rest/api/3/search/jql"
    jql_query = f"project = {PROJECT_KEY} ORDER BY created ASC"

    all_issues = []
    next_page_token = None

    while True:
        params = {
            "jql": jql_query,
            "maxResults": 50,
            "fields": "*all",
            "expand": "changelog",
        }
        if next_page_token:
            params["nextPageToken"] = next_page_token

        response = requests.get(url, headers=headers, params=params, auth=auth)
        if response.status_code != 200:
            raise RuntimeError(
                f"Erro na API do Jira ({response.status_code}): {response.text}"
            )

        data = response.json()
        issues = data.get("issues", [])
        all_issues.extend(issues)

        print(f"Página extraída: {len(issues)} chamados (Total acumulado: {len(all_issues)})")

        next_page_token = data.get("nextPageToken")
        if not next_page_token:
            break

    return all_issues


def load_to_bronze(issues):
    """Insere ou atualiza os payloads brutos (JSONB) na camada Bronze do Supabase."""
    if not issues:
        print("Nenhum chamado encontrado para carga.")
        return

    upsert_sql = """
        INSERT INTO bronze.raw_jira_issues (issue_key, raw_payload, jira_updated_at, ingested_at)
        VALUES (%s, %s, %s, NOW())
        ON CONFLICT (issue_key) DO UPDATE SET
            raw_payload = EXCLUDED.raw_payload,
            jira_updated_at = EXCLUDED.jira_updated_at,
            ingested_at = NOW();
    """

    conn = psycopg2.connect(SUPABASE_DB_URL)
    try:
        with conn:
            with conn.cursor() as cur:
                for issue in issues:
                    issue_key = issue["key"]
                    jira_updated_at = issue["fields"]["updated"]
                    cur.execute(
                        upsert_sql,
                        (issue_key, Json(issue), jira_updated_at),
                    )
        print(f"[SUCESSO] {len(issues)} registros carregados/atualizados em bronze.raw_jira_issues.")
    finally:
        conn.close()


if __name__ == "__main__":
    print("Iniciando extração da API do Jira...")
    issues_data = fetch_all_issues()
    print("Carregando dados na camada Bronze (Supabase)...")
    load_to_bronze(issues_data)