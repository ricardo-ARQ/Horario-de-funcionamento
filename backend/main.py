"""
Gestão de Horários — Diac/SGA
Backend FastAPI para persistência centralizada (Opção A)

Serve o frontend e expõe endpoints REST para salvar/carregar o estado da aplicação.
"""

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import json
import shutil
from datetime import datetime

# ─── Configuração de Caminhos ────────────────────────────────────────────────

BASE_DIR    = Path(__file__).parent
FRONTEND    = BASE_DIR.parent / "frontend" / "index.html"
DATA_DIR    = BASE_DIR / "data"
STATE_FILE  = DATA_DIR / "state.json"
BACKUP_DIR  = DATA_DIR / "backups"

DATA_DIR.mkdir(exist_ok=True)
BACKUP_DIR.mkdir(exist_ok=True)

# ─── App FastAPI ─────────────────────────────────────────────────────────────

app = FastAPI(
    title="Gestão de Horários — Diac/SGA",
    version="1.0.0",
    docs_url="/api/docs",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Frontend ────────────────────────────────────────────────────────────────

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def serve_app():
    """Serve a aplicação frontend."""
    if not FRONTEND.exists():
        return HTMLResponse("<h1>Erro: frontend/index.html não encontrado.</h1>", status_code=500)
    return HTMLResponse(content=FRONTEND.read_text(encoding="utf-8"))

# ─── API de Estado ───────────────────────────────────────────────────────────

@app.get("/api/state")
async def get_state():
    """Retorna o estado completo salvo da aplicação."""
    if not STATE_FILE.exists():
        return JSONResponse(content=None, status_code=404)
    try:
        content = STATE_FILE.read_text(encoding="utf-8")
        return JSONResponse(content=json.loads(content))
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)


@app.post("/api/state")
async def save_state(request: Request):
    """Salva o estado completo da aplicação."""
    try:
        body = await request.json()

        # Valida estrutura mínima
        if not isinstance(body, dict) or "sectors" not in body or "centralDatabase" not in body:
            return JSONResponse({"error": "Estado inválido"}, status_code=400)

        # Salva backup rotativo (mantém últimos 20)
        if STATE_FILE.exists():
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = BACKUP_DIR / f"state_{ts}.json"
            shutil.copy2(STATE_FILE, backup_path)

            # Mantém apenas os 20 backups mais recentes
            backups = sorted(BACKUP_DIR.glob("state_*.json"))
            for old in backups[:-20]:
                old.unlink()

        # Persiste estado atual
        STATE_FILE.write_text(
            json.dumps(body, ensure_ascii=False, indent=2),
            encoding="utf-8"
        )

        return JSONResponse({"ok": True})

    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)


@app.get("/api/status")
async def status():
    """Health check — verifica se o servidor está rodando."""
    return {
        "status": "online",
        "state_exists": STATE_FILE.exists(),
        "state_size_kb": round(STATE_FILE.stat().st_size / 1024, 1) if STATE_FILE.exists() else 0,
        "backups": len(list(BACKUP_DIR.glob("state_*.json")))
    }
