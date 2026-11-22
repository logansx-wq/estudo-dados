import os
import random
import time
import requests
from requests.auth import HTTPBasicAuth
from dotenv import load_dotenv

load_dotenv()

JIRA_URL = os.getenv("JIRA_BASE_URL").rstrip("/")
JIRA_EMAIL = os.getenv("JIRA_EMAIL")
JIRA_TOKEN = os.getenv("JIRA_API_TOKEN")
PROJECT_KEY = os.getenv("JIRA_PROJECT_KEY")

auth = HTTPBasicAuth(JIRA_EMAIL, JIRA_TOKEN)
headers = {
    "Accept": "application/json",
    "Content-Type": "application/json"
}

def get_project_metadata():
    """Verifica os tipos de issue disponíveis no projeto para evitar erro de configuração."""
    url = f"{JIRA_URL}/rest/api/3/issue/createmeta/{PROJECT_KEY}/issuetypes"
    response = requests.get(url, headers=headers, auth=auth)
    if response.status_code != 200:
        print(f"Erro ao conectar no Jira ({response.status_code}): {response.text}")
        return None
    
    issue_types = response.json().get("issueTypes", [])
    print("Tipos de chamados disponíveis no seu projeto:")
    for it in issue_types:
        print(f" - ID: {it['id']} | Nome: {it['name']}")
    return issue_types

def create_and_transition_issue(issue_type_id, summary, priority_name, queue_label):
    """Cria um chamado via POST e simula transições de status para gerar changelog."""
    create_url = f"{JIRA_URL}/rest/api/3/issue"
    
    payload = {
        "fields": {
            "project": {"key": PROJECT_KEY},
            "summary": summary,
            "issuetype": {"id": issue_type_id},
            "labels": [queue_label],
            "description": {
                "type": "doc",
                "version": 1,
                "content": [
                    {
                        "type": "paragraph",
                        "content": [{"type": "text", "text": f"Chamado gerado via pipeline de estudos - Fila: {queue_label}"}]
                    }
                ]
            }
        }
    }

    res = requests.post(create_url, json=payload, headers=headers, auth=auth)
    if res.status_code != 201:
        print(f"Falha ao criar issue: {res.status_code} - {res.text}")
        return None

    issue_key = res.json()["key"]
    print(f"[CRIADO] {issue_key} - {summary}")

    # Consulta quais transições de status estão disponíveis para este chamado
    trans_url = f"{JIRA_URL}/rest/api/3/issue/{issue_key}/transitions"
    trans_res = requests.get(trans_url, headers=headers, auth=auth).json()
    transitions = trans_res.get("transitions", [])

    # Simula avanço de etapas (ex: mover para 'Em andamento' e eventualmente 'Concluído')
    if transitions:
        # Escolhe 1 ou 2 transições aleatórias para simular ciclo de vida
        steps = random.choice([0, 1, 2])
        for _ in range(steps):
            current_trans = requests.get(trans_url, headers=headers, auth=auth).json().get("transitions", [])
            if not current_trans:
                break
            chosen = random.choice(current_trans)
            requests.post(trans_url, json={"transition": {"id": chosen["id"]}}, headers=headers, auth=auth)
            print(f"   -> Movido para status: {chosen['to']['name']}")
            time.sleep(0.5) # Pequena pausa para diferenciar timestamps no changelog

    return issue_key

if __name__ == "__main__":
    types = get_project_metadata()
    if types:
        # Pega o primeiro tipo válido (ex: Task / Tarefa / Incidente) que não seja sub-tarefa
        valid_type = next((t for t in types if not t.get("subtask")), types[0])
        
        filas = ["Fila_N1_Suporte", "Fila_N2_Sistemas", "Fila_Infra_Cloud", "Fila_Banco_Dados"]
        problemas = [
            "Erro 504 Gateway Timeout no checkout",
            "Lentidão na integração de pedidos API",
            "Falha de autenticação SSO",
            "Solicitação de acesso ao banco de produção",
            "Queda de worker na fila de processamento",
            "Divergência de saldo no fechamento diário"
        ]

        print(f"\nIniciando criação de 15 chamados de teste usando tipo '{valid_type['name']}'...\n")
        for i in range(15):
            tema = f"{random.choice(problemas)} #{i+1}"
            fila = random.choice(filas)
            create_and_transition_issue(valid_type["id"], tema, "High", fila)