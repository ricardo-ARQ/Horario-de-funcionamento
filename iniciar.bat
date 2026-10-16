@echo off
chcp 65001 >nul
title Gestao de Horarios - Diac/SGA

echo.
echo  ============================================================
echo   Gestao de Horarios - Diac/SGA   ^|   Servidor Web
echo  ============================================================
echo.

REM --- 1. Tenta verificar se ha Python valido e funcional ---
set PYTHON_EXE=
python --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_EXE=python
)

REM --- 2. Se Python estiver disponivel, usa FastAPI ---
if not "%PYTHON_EXE%"=="" (
    echo  [OK] Usando Python: %PYTHON_EXE%
    cd /d "%~dp0backend"
    if not exist ".deps_ok" (
        echo  [INFO] Instalando dependencias do Python...
        "%PYTHON_EXE%" -m pip install -r requirements.txt --quiet
        if not errorlevel 1 (
            echo. > .deps_ok
        )
    )
    echo  [OK] Servidor iniciando em: http://localhost:8000
    start http://localhost:8000
    "%PYTHON_EXE%" -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    goto FIM
)

REM --- 3. Se Python nao estiver instalado, usa o servidor nativo PowerShell (Zero Dependencias) ---
echo  [INFO] Python nao detectado. Iniciando servidor nativo do Windows (PowerShell)...
echo.
echo  ============================================================
echo   Servidor Ativo em: http://localhost:8000
echo   (Seu navegador sera aberto automaticamente)
echo  ============================================================
echo.

start http://localhost:8000
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0backend\server.ps1"

:FIM
pause
