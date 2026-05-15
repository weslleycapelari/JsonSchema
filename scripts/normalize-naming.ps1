# Script de Normaliza˜˜o Global de Naming para JsonSchema

$srcPath = 'c:\Users\weslley.capelari\Documents\Projetos\Github\weslleycapelari\JsonSchema\src'
$files = Get-ChildItem -Path $srcPath -Filter '*.pas'

Write-Host "Iniciando normaliza˜˜o de naming..." -ForegroundColor Cyan
Write-Host "Arquivos encontrados: $($files.Count)" -ForegroundColor Cyan
Write-Host ""

$count = 0
$details = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    $changes = @()

    # 1. Par˜metros: A[A-Z] => p[A-Z]
    # Padr˜o: precedido por espa˜o, v˜rgula, par˜ntese ou ponto-e-v˜rgula
    if ($content -match 'A[A-Z]') {
        $content = $content -replace '(\s|,|\(|;)A([A-Z][a-zA-Z0-9]*)', '$1p$2'
        $changes += "Par˜metros A?p"
    }

    # 2. Vari˜veis locais: L[A-Z] => l[A-Z]
    # Padr˜o: precedidas por espa˜o ou em in˜cio de linha ap˜s 'var'
    if ($content -match '\sL[A-Z]') {
        $content = $content -replace '(\s)L([A-Z][a-zA-Z0-9]*)', '$1l$2'
        $changes += "Vari˜veis L?l"
    }

    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content
        $count++
        $details += "$($file.Name): $($changes -join ', ')"
        Write-Host "? $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=" * 60
Write-Host "RESUMO: Total de arquivos atualizados: $count" -ForegroundColor Cyan
Write-Host "=" * 60

foreach ($detail in $details) {
    Write-Host $detail
}
