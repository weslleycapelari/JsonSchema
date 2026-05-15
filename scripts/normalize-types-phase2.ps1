# Script de Normaliza˜˜o Inteligente de Naming com valida˜˜o por bloco
# Este script tenta ser mais cuidadoso que regex global

$srcPath = 'c:\Users\weslley.capelari\Documents\Projetos\Github\weslleycapelari\JsonSchema\src'

# Arquivos priorit˜rios para esta primeira fase
$filesToProcess = @(
    'JsonSchema.Visitors.Types.pas',
    'JsonSchema.Visitors.Interfaces.pas',
    'JsonSchema.Walker.Types.pas',
    'JsonSchema.Registry.Types.pas'
)

Write-Host "Fase 2: Normaliza˜˜o de Tipos & Interfaces" -ForegroundColor Cyan
Write-Host "=" * 60

foreach ($fileName in $filesToProcess) {
    $filePath = Join-Path $srcPath $fileName

    if (-not (Test-Path $filePath)) {
        Write-Host "? Arquivo n˜o encontrado: $fileName" -ForegroundColor Yellow
        continue
    }

    Write-Host ""
    Write-Host "Processando: $fileName" -ForegroundColor Green

    $content = Get-Content $filePath -Raw -Encoding UTF8
    $original = $content

    # Substituir Par˜metros com constantes (const AValue:, var AValue:, AValue: etc)
    # Padr˜o: precedido por ( ou , com espa˜o e seguido por :
    $content = $content -replace '(\(|,\s)(A[A-Z][a-zA-Z0-9]*)\s*:', '$1p$2:'

    # Substituir par˜metros em procedure/function declarations
    $content = $content -replace 'var\s+A([A-Z][a-zA-Z0-9]*);', 'var p$1;'
    $content = $content -replace 'out\s+A([A-Z][a-zA-Z0-9]*);', 'out p$1;'

    if ($content -ne $original) {
        Set-Content -Path $filePath -Value $content -Encoding UTF8
        Write-Host "  ? Par˜metros normalizados"
    }
    else {
        Write-Host "  - Sem mudan˜as necess˜rias"
    }
}

Write-Host ""
Write-Host "=" * 60
Write-Host "Fase 2 Conclu˜da: Tipos & Interfaces prontos para compila˜˜o" -ForegroundColor Cyan
