# Script de Normaliza˜˜o Cuidadosa de Naming para JsonSchema
# Estrat˜gia: Usar padr˜es Delphi-espec˜ficos para evitar falsos positivos

$srcPath = 'c:\Users\weslley.capelari\Documents\Projetos\Github\weslleycapelari\JsonSchema\src'
$files = Get-ChildItem -Path $srcPath -Filter '*.pas' | Sort-Object Name

Write-Host "Iniciando normaliza˜˜o cuidadosa de naming..." -ForegroundColor Cyan
Write-Host "Arquivos encontrados: $($files.Count)`n" -ForegroundColor Cyan

$count = 0
$details = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $original = $content
    $fileChanges = @()

    # 1. Normalizar par˜metros: (espacoou,ou( + A + MAI˜SCULA + resto)
    # Mas NUNCA dentro de uma palavra como "Array"
    # Padr˜o: (\(|,\s)A([A-Z][a-zA-Z0-9]*)([,:\)])
    # Isso garante que A n˜o est˜ dentro de outra palavra

    # Caso 1: Ap˜s ( ou , com espa˜o: "function foo(AValue: T)" ou ", AValue"
    $newContent = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        '(\(|,\s)A([A-Z][a-zA-Z0-9]*)(\s*[:;,\)])',
        { param($m) $m.Groups[1].Value + 'p' + $m.Groups[2].Value + $m.Groups[3].Value },
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    if ($newContent -ne $content) {
        $fileChanges += "Par˜metros normalizados (A?p)"
        $content = $newContent
    }

    # 2. Normalizar vari˜veis locais: \s + L + MAI˜SCULA + resto
    # Padr˜o: (\s|;|begin\s)L([A-Z][a-zA-Z0-9]*)([,;:\s=\)])
    # Garantir que L n˜o est˜ dentro de outra palavra

    $newContent = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        '(\s|;|begin\s)L([A-Z][a-zA-Z0-9]*)(\s*[:;,=\)\[])',
        { param($m) $m.Groups[1].Value + 'l' + $m.Groups[2].Value + $m.Groups[3].Value },
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    if ($newContent -ne $content) {
        $fileChanges += "Vari˜veis locais normalizadas (L?l)"
        $content = $newContent
    }

    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        $count++
        $details += "$($file.Name): $($fileChanges -join '; ')"
        Write-Host "? $($file.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "- $($file.Name) (sem mudan˜as)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "RESUMO: Total de arquivos atualizados: $count" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

if ($details.Count -gt 0) {
    foreach ($detail in $details) {
        Write-Host $detail
    }
}
