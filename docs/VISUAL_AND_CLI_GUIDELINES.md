# Diretrizes Visuais e de CLI para Ferramentas VCL (Design System & CLI Standards)

Este documento estabelece as **diretrizes de design e padrões de interface** para todas as ferramentas auxiliares da biblioteca Delphi JSON Schema. Ele define a identidade visual comum das aplicações desktop VCL e unifica a interface de linha de comando (CLI) para garantir consistência, usabilidade e facilidade de automação.

---

## 1. Identidade Visual (VCL Desktop Applications)

Para que o usuário identifique instantaneamente que as ferramentas pertencem ao mesmo ecossistema, todas devem aderir ao seguinte guia de estilo visual:

### A. Paleta de Cores e Estilo Teomático
*   **Tema Nativo Moderno**: Toda aplicação VCL deve conter a unidade `Vcl.XPMan` em seu arquivo `.dpr`. Isso habilita os temas visuais nativos do Windows (como o estilo do Windows 11) nas janelas e botões.
*   **Cores do Sistema**: Para garantir a compatibilidade com o Modo Escuro/Claro do Windows e temas de alto contraste, **evite cores hardcoded** em painéis e janelas. Use as cores padrão do sistema:
    *   Fundo do formulário / painéis: `clBtnFace`
    *   Texto do formulário: `clWindowText`
    *   Áreas de edição (TMemo, TEdit): fundo `clWindow` e texto `clWindowText`
*   **Cores de Status (Indicadores Semânticos)**:
    *   *Sucesso / Pronto*: Verde Escuro (`clGreen` ou `$00008000`)
    *   *Aviso / Progresso*: Amarelo/Laranja Escuro (`$000288D1`)
    *   *Erro / Falha*: Vermelho (`clRed` ou `$000000FF`)
    *   *Destaques / Links*: Azul Clássico (`clHotLight` ou `$00CC6600`)

### B. Layout Padrão de Janela
*   **Posicionamento**: Sempre configure o formulário principal (`TForm`) com `Position = poScreenCenter`.
*   **Resolução e Proporção**:
    *   Largura padrão: `884` pixels.
    *   Altura padrão: varia entre `561` e `620` pixels dependendo da quantidade de CheckBoxes de configuração.
*   **Interface Dividida (Split View)**:
    *   **Painel Esquerdo (`pnlLeft`)**: Largura fixa de `380` pixels (`Align = alLeft`), contendo os inputs do usuário, arquivos de carregamento e CheckBoxes de opções.
    *   **Divisor (`splSplitter`)**: Um `TSplitter` (`Align = alLeft`, `Width = 5`, `Cursor = crHSplit`) para permitir redimensionamento horizontal.
    *   **Painel Direito (`pnlRight`)**: Ocupa o restante da tela (`Align = alClient`), exibindo os resultados gerados, erros e botões de ação final.

### C. Tipografia e Controles de Código
*   **Fontes de Interface**: Use a fonte padrão do sistema para textos gerais: `Segoe UI`, tamanho `9` ou `10`.
*   **Visualização de JSON / Código**:
    *   Todos os controles `TMemo` que exibem schemas, instâncias de dados ou SQL DDL devem usar uma fonte monospace: `Consolas`, tamanho `9` ou `10`.
    *   Propriedades obrigatórias para Memos de Código:
        *   `ScrollBars = ssBoth`
        *   `WordWrap = False`
        *   `ReadOnly = True` (para painéis de resultado)

### D. Margens e Padding (Espaçamento)
*   **Alinhamento de Margens**: Mantenha uma margem de segurança de `16` pixels em relação às bordas do formulário para todos os botões e caixas de texto.
*   **Status Bar**: Inclua um painel inferior (`pnlStatus`, `Align = alBottom`, `Height = 30`) para feedbacks rápidos e amigáveis ao usuário.

---

## 2. Padrões de Linha de Comando (CLI Standards)

A consistência nas CLIs permite que desenvolvedores criem scripts de integração de forma previsível e ágil.

### A. Tabela de Argumentos Padronizados

| Argumento Curto | Argumento Longo | Valor | Descrição |
| :--- | :--- | :--- | :--- |
| `-i` | `--input` | `<path>` | **Obrigatório**. Caminho para o arquivo ou diretório de entrada (schema, JSON ou código). |
| `-o` | `--output` | `<path>` | **Opcional**. Destino do resultado gerado. Se omitido, imprime o resultado no `stdout`. |
| `-d` | `--draft` | `<version>` | **Opcional**. Especificação do Draft (ex: `2020-12`, `draft7`). |
| `-l` | `--locale` | `<locale>` | **Opcional**. Idioma das mensagens (ex: `en-US`, `pt-BR`). |
| `-h` | `--help` | *(Nenhum)* | Exibe o menu de ajuda com a lista de parâmetros e exemplos. |
| *(Nenhum)* | `--minify` | *(Nenhum)* | Desabilita a indentação no JSON de saída para gerar arquivos menores. |
| *(Nenhum)* | `--quiet` | *(Nenhum)* | Modo silencioso. Suprime saídas informativas e de progresso, imprimindo apenas erros graves. |

### B. Fallback Posicional
Se o usuário passar apenas um argumento na linha de comando sem nenhuma flag (ex: `SchemaValidatorCLI.exe C:\schema.json`), o parser deve interpretá-lo automaticamente como o parâmetro de entrada `--input`.

### C. Códigos de Retorno (Exit Codes)
*   `0`: Execução finalizada com absoluto sucesso.
*   `1`: Ocorreu uma falha na validação, erro de parâmetros, arquivo não encontrado ou exceção de execução.

### D. Formatação de Erros na CLI
Todos os erros técnicos, falhas de leitura ou exceções geradas devem ser impressos no fluxo de saída de erros padrão (`ErrOutput` / `stderr`), nunca no `stdout`. Isso permite que saídas úteis sejam redirecionadas via pipes de comando (ex: `tool.exe -i schema.json > output.json`) sem misturar logs de erro no payload gerado.

---

## 3. Matriz de Aplicação das Diretrizes

Abaixo está o mapeamento de como as ferramentas existentes aplicam essas regras e como as futuras ferramentas devem ser moldadas:

| Ferramenta | Padrão VCL Aplicado | Flags CLI Suportadas |
| :--- | :--- | :--- |
| **SchemaValidator** | Split View, Segoe UI, Consolas | `-s` (sinônimo de `-i`), `-o`, `-d`, `-l` |
| **SchemaMockGen** | Split View, Visual status | `-s` (sinônimo de `-i`), `-o` |
| **Schema2Delphi** | Split View, Consolas | `-s` (sinônimo de `-i`), `-o` |
| **Delphi2Schema** | Painel simples, RTTI scan | `-t` (input type), `-o` |
| **Schema2DDL** | Split View, SQL monospace | `-s` (sinônimo de `-i`), `-o`, `-d` |
| **Schema2REST** | Split View | `-s` (sinônimo de `-i`), `-o` |
| **JSON2Schema** | Split View, Indent options | `-i`, `-o`, `-d`, `--minify` |
| **Schema2Doc** | Split View, HTML layout | `-s` (sinônimo de `-i`), `-o` |
| **SchemaLinter** | TreeView, Severity list | `-s` (sinônimo de `-i`), `-o` |
| **SchemaBundler** | Split View, Monospace | `-i`, `-o`, `--minify` |
| **SchemaMigrator** | Split View, Consolas | `-i`, `-o`, `--minify` |
| **SchemaOptimizer** | Split View, Stats Bar, Consolas | `-i`, `-o`, `--minify`, `--no-unused`, `--no-allof` |
| **VisualTestSuiteRunner** | TreeView, Split View, Consolas, Status Bar | `-i`, `-d`, `-o`, `--quiet` |
| *(Futuras)* | **Obrigatório seguir este padrão** | **Obrigatório seguir este padrão** |
