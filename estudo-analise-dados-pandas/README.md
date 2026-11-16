# Estudo - Análise e Tratamento de Dados de Vendas com Pandas

Estudo de dados desenvolvido com Python e Pandas, integrando tabelas fato e dimensões para apuração de faturamento, rentabilidade e desempenho comercial.

## Estrutura 
- `Cadastros.xlsx`: Tabelas dimensionais (`dProdutos`, `dClientes`, `dVendedores`).
- `Vendas.xlsx`: Registos de transações de vendas (`fVendas`).
- `Metas.csv`: Metas comerciais mensais por vendedor.
- `analise.py`: Script principal de ingestão, limpeza, enriquecimento e exportação.
- `vendas_consolidadas.csv`: Base tratada pronta para consumo analítico.
- <img width="644" height="198" alt="image" src="https://github.com/user-attachments/assets/906b5853-3aba-4f8e-b854-c01a190c4fea" />

## Tratamentos Realizados
1. **Limpeza e Padronização:**
   - Remoção de registos nulos cadastrais.
   - Conversão de identificadores (`ID_Cliente`) para inteiros.
   - Tratamento de caracteres especiais e formatação de datas (`Mes_Ref`).
   - Normalização de tipos numéricos e separadores decimais em CSV.
2. **Métricas:**
   - Faturamento Bruto, Valor de Desconto e Faturamento Líquido.
   - Custo Operacional Total, Lucro Bruto e Margem de Lucro percentual.
3. **Modelagem Relacional (Merges):**
   - Cruzamento entre a tabela fato de vendas e as três dimensões de suporte.
<img width="316" height="302" alt="image" src="https://github.com/user-attachments/assets/54553d35-d5bf-43e5-b365-bb217e636459" />



## Como Executar
1. Instale as dependências:
   ```bash
   pip install pandas openpyxl
2. Execute o arquivo "analise.py"
<img width="614" height="178" alt="image" src="https://github.com/user-attachments/assets/225e977e-27ab-4a2c-af66-06c1ec87d0d9" />

