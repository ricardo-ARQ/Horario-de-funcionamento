# 📅 Gestão de Horários — Diac/SGA (Versão Web)

Sistema de administração de carga horária dos servidores, agora como **aplicação web centralizada**.

---

## 🚀 Como iniciar

### 1. Pré-requisito: Python 3.8+
Verifique se está instalado:
```
python --version
```
Se não estiver: https://www.python.org/downloads/

### 2. Iniciar o servidor (Windows)
Dê **duplo clique** em:
```
iniciar.bat
```
Na primeira execução, as dependências serão instaladas automaticamente.

### 3. Acessar no navegador
```
http://localhost:8000
```

### 4. Compartilhar na rede do IFRN
Descubra o IP do computador servidor:
```
ipconfig
```
Outros computadores na mesma rede acessam:
```
http://SEU_IP:8000
```
Exemplo: `http://192.168.1.50:8000`

---

## 📁 Estrutura do Projeto

```
CH Web/
├── frontend/
│   └── index.html          ← Interface da aplicação (baseada no V20.html)
├── backend/
│   ├── main.py             ← Servidor FastAPI
│   ├── requirements.txt    ← Dependências Python
│   └── data/
│       ├── state.json      ← Estado atual da aplicação
│       └── backups/        ← Backups automáticos (últimos 20)
├── iniciar.bat             ← Script de inicialização (Windows)
└── README.md               ← Este arquivo
```

---

## 💾 Dados e Backups

- O estado da aplicação é salvo em `backend/data/state.json`
- A cada alteração, um backup automático é criado em `backend/data/backups/`
- Os últimos **20 backups** são mantidos automaticamente
- Você também pode usar o botão **"Exportar JSON"** na interface para backup manual

---

## 🔧 API Endpoints

| Método | Endpoint      | Descrição                          |
|--------|---------------|-------------------------------------|
| GET    | `/`           | Serve a interface da aplicação      |
| GET    | `/api/state`  | Retorna o estado salvo              |
| POST   | `/api/state`  | Salva o estado atual                |
| GET    | `/api/status` | Health check do servidor            |
| GET    | `/api/docs`   | Documentação interativa da API      |

---

## ✅ Funcionalidades preservadas e novas

Toda a interface original foi mantida e aprimorada:
- Grade semanal (30min com horário início e fim exibidos, 45min, 1h, Blocos)
- **Novo Modo de Exibição "Por Servidor (Entrada/Saída)":**
  - Colunas: Dias da semana (`SEG`, `TER`, `QUA`, `QUI`, `SEX`) + Servidor + Total semanal
  - Linhas: Servidores em ordem alfabética (A-Z)
  - Células: Intervalos consolidados de entrada e saída (ex: `07:00 - 11:30`), carga horária entre parênteses `(4.5h)` e indicação visual com selo explícito de `PRESENCIAL` ou `TELETRABALHO`
- Modo Pincel e Drag & Drop na grade
- **Filtro Individual Compacto:** Opção *"Apenas filtrado (compacto)"* para exibir somente os blocos ou linhas do servidor selecionado
- **Exportação PDF Integral:** Captura a grade inteira de 07:00 às 22:00 sem cortes ou limitações de rolagem da tela
- **Orientação Retrato ou Paisagem:** Modal para escolher entre impressão/PDF em Retrato (vertical) ou Paisagem (horizontal)
- **Drag & Drop de Setores:** Reordenação da posição das abas de setores na barra superior
- **Relocação de Servidores por Drag & Drop:** Arraste servidores (da Base Central ou de outro setor) e solte sobre a aba do setor desejado para adicioná-los/transferi-los
- Presencial / Remoto (Teletrabalho)
- Importação Excel (.xlsx) / CSV
- Exportação PDF e Impressão
- Múltiplos setores / cenários
- Alertas de sobrecarga de CH
- Base Central de Servidores
- Backup JSON (exportar/importar)

---

*Versão Web — atualizada em 02/10/2026*
