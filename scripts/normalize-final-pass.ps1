# Script Final: Normaliza��o Global de Naming com estrat�gia estruturada
# Estrat�gia: Usar padr�es muito espec�ficos do Delphi para evitar falsos positivos

$srcPath = 'c:\Users\weslley.capelari\Documents\Projetos\Github\weslleycapelari\JsonSchema\src'

# Arquivos j� normalizados - pular
$done = @('JsonSchema.Validation.Types.pas', 'JsonSchema.Validation.Interfaces.pas', 'JsonSchema.Visitors.Interfaces.pas')

$files = Get-ChildItem -Path $srcPath -Filter '*.pas' |
         Where-Object { $done -notcontains $_.Name } |
         Sort-Object Name

Write-Host "Normaliza��o Final de Naming - $($files.Count) arquivos" -ForegroundColor Cyan
Write-Host "=" * 70

$count = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $original = $content

    # ==================== ESTRAT�GIA ====================
    # 1. Par�metros: Usar contexto de declara��o (function/procedure)
    #    Padr�o: "const A..." ou "var A..." ou "out A..." ou "(A..."
    # 2. Vari�veis locais: Usar contexto de declara��o local
    #    Padr�o: "var L..." ou "begin L..." (ap�s espa�o em linha)

    # --- FASE 1: Par�metros em declarations ---

    # Substituir "const AXxx:" ou "const pXxx:" conforme necess�rio
    $content = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        '(\b(?:const|var|out)\s+)A([A-Z][a-zA-Z0-9]*)\s*:',
        '$1p$2:',
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    # Substituir "(AXxx:" ou ", AXxx:" em function/procedure declarations
    $content = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        '([,(\s])A([A-Z][a-zA-Z0-9]*)\s*:',
        '$1p$2:',
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    # --- FASE 2: Vari�veis locais em var declarations ---

    # Substituir "var LXxx:" ap�s espa�o
    $content = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        '(\bvar\s+)L([A-Z][a-zA-Z0-9]*)\s*:',
        '$1l$2:',
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    # Substituir ", LXxx:" em var statements
    $content = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        '(,\s*)L([A-Z][a-zA-Z0-9]*)\s*:',
        '$1l$2:',
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    # --- FASE 3: Refer�ncias em assignments ---

    # Substituir " := AXxx" (refer�ncia a par�metro)
    $content = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        '(\s:=\s)A([A-Z][a-zA-Z0-9]*)(\W)',
        '$1p$2$3',
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    # Substituir " := LXxx" (refer�ncia a vari�vel)
    $content = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        '(\s:=\s)L([A-Z][a-zA-Z0-9]*)(\W)',
        '$1l$2$3',
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
        $count++
        Write-Host "? $($file.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "- $($file.Name)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=" * 70
Write-Host "Fase Final: $count arquivos normalizados" -ForegroundColor Cyan
Write-Host "Pronto para compila��o!" -ForegroundColor Green
