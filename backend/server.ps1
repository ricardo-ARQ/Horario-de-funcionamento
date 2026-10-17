# Servidor Web Nativo PowerShell para Gestão de Horários — Diac/SGA
# Roda diretamente no Windows sem necessidade de instalar interpretadores externos.

param(
    [int]$Port = 8000
)

$Host.UI.RawUI.WindowTitle = "Servidor Web - Gestão de Horários (Diac/SGA)"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$frontendHtml = Join-Path $projectRoot "frontend\index.html"
$dataDir = Join-Path $scriptDir "data"
$stateFile = Join-Path $dataDir "state.json"
$backupDir = Join-Path $dataDir "backups"

if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")

try {
    $listener.Start()
} catch {
    Write-Host "[ERRO] Não foi possível iniciar na porta $Port : $_" -ForegroundColor Red
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Gestão de Horários - Diac/SGA | Servidor Ativo" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Acesse no seu navegador: http://localhost:$Port" -ForegroundColor Yellow
Write-Host " Pressione Ctrl+C para encerrar o servidor" -ForegroundColor Gray
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.AbsolutePath
        $method = $request.HttpMethod
        
        # CORS headers
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        if ($method -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] $method $path" -ForegroundColor DarkCyan

        if ($path -eq "/" -or $path -eq "/index.html") {
            if (Test-Path $frontendHtml) {
                $bytes = [System.IO.File]::ReadAllBytes($frontendHtml)
                $response.ContentType = "text/html; charset=utf-8"
                $response.ContentLength64 = $bytes.Length
                $response.StatusCode = 200
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $msg = [System.Text.Encoding]::UTF8.GetBytes("<h1>Erro: frontend/index.html não encontrado</h1>")
                $response.StatusCode = 404
                $response.OutputStream.Write($msg, 0, $msg.Length)
            }
        }
        elseif ($path -eq "/api/state") {
            if ($method -eq "GET") {
                if (Test-Path $stateFile) {
                    $bytes = [System.IO.File]::ReadAllBytes($stateFile)
                    $response.ContentType = "application/json; charset=utf-8"
                    $response.ContentLength64 = $bytes.Length
                    $response.StatusCode = 200
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                } else {
                    $response.StatusCode = 404
                    $msg = [System.Text.Encoding]::UTF8.GetBytes('{"error": "Estado ainda não salvo"}')
                    $response.ContentType = "application/json"
                    $response.OutputStream.Write($msg, 0, $msg.Length)
                }
            }
            elseif ($method -eq "POST") {
                try {
                    $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                    $bodyText = $reader.ReadToEnd()
                    
                    if (Test-Path $stateFile) {
                        $ts = Get-Date -Format "yyyyMMdd_HHmmss"
                        $backupFile = Join-Path $backupDir "state_$ts.json"
                        Copy-Item -Path $stateFile -Destination $backupFile -Force
                        
                        $oldBackups = Get-ChildItem -Path $backupDir -Filter "state_*.json" | Sort-Object CreationTime -Descending | Select-Object -Skip 20
                        if ($oldBackups) { $oldBackups | Remove-Item -Force }
                    }

                    [System.IO.File]::WriteAllText($stateFile, $bodyText, [System.Text.Encoding]::UTF8)

                    $respBytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok": true}')
                    $response.ContentType = "application/json"
                    $response.StatusCode = 200
                    $response.OutputStream.Write($respBytes, 0, $respBytes.Length)
                    Write-Host "  -> Estado salvo com sucesso!" -ForegroundColor Green
                } catch {
                    Write-Host "  -> Erro ao salvar estado: $_" -ForegroundColor Red
                    $response.StatusCode = 500
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("{`"error`": `"$($_)`"}")
                    $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                }
            }
        }
        elseif ($path -eq "/api/status") {
            $stateExists = Test-Path $stateFile
            $statusObj = @{
                status = "online"
                state_exists = $stateExists
                port = $Port
                runtime = "PowerShell Native"
            }
            $json = $statusObj | ConvertTo-Json
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        else {
            $response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("Rota não encontrada")
            $response.OutputStream.Write($msg, 0, $msg.Length)
        }

        $response.Close()
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
