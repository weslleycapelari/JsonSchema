# Relatório de Qualidade — `JsonSchema` (src/)

**Data:** 15/05/2026 | **Auditores:** 5 subagentes especializados Delphi Standards Reviewer
**Escopo:** 20 arquivos `.pas` — todas as camadas do projeto

---

## Sumário Executivo — Pontuações por Arquivo

| Camada | Arquivo | Saúde | Prioridade |
| --- | --- | --- | --- |
| **Core** | `JsonSchema.pas` | **68%** | 🟠 Média |
| **Core** | `JsonSchema.Common.Utils.pas` | **57%** | 🔴 Alta |
| **Registry** | `Registry.Base.pas` | **62%** | 🔴 Alta |
| **Registry** | `Registry.Resource.pas` | **58%** | 🔴 Alta |
| **Registry** | `Registry.Utils.pas` | **64%** | 🔴 Alta |
| **Registry** | `Registry.Uri.Builder.pas` | **70%** | 🟠 Média |
| **Registry** | `Registry.Uri.pas` | **74%** | 🟠 Média |
| **Registry** | `Registry.Uri.Validator.pas` | **82%** | 🟡 Baixa |
| **Registry** | `Registry.Uri.ParseResult.pas` | **85%** | 🟡 Baixa |
| **Registry** | `Registry.Types.pas` | **95%** | ✅ Ok |
| **Translation** | `Translate.Interfaces.pas` | **82%** | 🟡 Baixa |
| **Translation** | `Translate.Types.pas` | **70%** | 🟠 Média |
| **Translation** | `Translate.Utils.pas` | **75%** | 🟠 Média |
| **Translation** | `Translate.enUS.pas` | **78%** | 🟠 Média |
| **Translation** | `Translate.ptBR.pas` | **62%** | 🔴 Alta |
| **Validation** | `Validation.Interfaces.pas` | **92%** | ✅ Ok |
| **Validation** | `Validation.Types.pas` | **85%** | 🟡 Baixa |
| **Validation** | `Validation.Base.pas` | **48%** | 🔴 CRÍTICO |
| **Validation** | `Validation.Draft6.pas` | **55%** | 🔴 Alta |
| **Validation** | `Validation.Draft7.pas` | **52%** | 🔴 Alta |
| **Validation** | `Validation.Draft2019_09.pas` | **47%** | 🔴 CRÍTICO |
| **Validation** | `Validation.Draft2020_12.pas` | **50%** | 🔴 Alta |
| **Visitors** | `Visitors.Interfaces.pas` | **78%** | 🟠 Média |
| **Visitors** | `Visitors.Types.pas` | **80%** | 🟠 Média |
| **Visitors** | `Visitors.Base.pas` | **52%** | 🔴 CRÍTICO |
| **Walker** | `Walker.Types.pas` | **74%** | 🟠 Média |
| **Walker** | `Walker.pas` | **35%** | 🔴 CRÍTICO |

**Média geral do projeto: ~67%** — Necessita refatoração estruturada antes de novos features.

---

## PARTE 1 — Violações Críticas Consolidadas

> Itens que **devem** ser corrigidos imediatamente — risco de bug, vazamento ou comportamento indefinido.

### 🔴 C-1 — Uso de `with` (PROIBIDO) — 9 arquivos afetados

O operador `with` está completamente proibido pelos padrões Delphi do projeto e aparece em:

| Arquivo | Ocorrências |
| --- | --- |
| JsonSchema.Registry.Base.pas | 3× (linhas 181, 303, 341) |
| JsonSchema.Registry.Uri.Builder.pas | 1× (linha 101) |
| JsonSchema.Visitors.Base.pas | 1× (linha 95) |
| JsonSchema.Validation.Base.pas | 5×+ (`VisitConst`, `VisitEnum`, `VisitRef`…) |
| JsonSchema.Validation.Draft6.pas | 3×+ (`VisitContains`, `VisitDependencies`, `VisitPropertyNames`) |
| JsonSchema.Validation.Draft7.pas | 6×+ (todos os visitors de if/then/else/contains) |
| JsonSchema.Validation.Draft2019_09.pas | 5×+ |
| JsonSchema.Validation.Draft2020_12.pas | Confirmado |

**Ação:** substituir cada `with LX do begin ... end` pelo acesso qualificado `LX.Field :=` explícito.

---

### 🔴 C-2 — Uso de `Break` e `Continue` (PROIBIDOS) — 5 arquivos afetados

| Arquivo | Tipo | Ocorrências |
| --- | --- | --- |
| JsonSchema.Common.Utils.pas | `Break` | 1× (`JsonArrayEquals`) |
| JsonSchema.Validation.Base.pas | `Break` | 3× (`VisitEnum`, `VisitRef` 2×) |
| JsonSchema.Validation.Draft2019_09.pas | `Break` | 1× (`VisitVocabulary`) |
| JsonSchema.Walker.pas | `Break` | 2× + `Continue` 5× |
| JsonSchema.Registry.Utils.pas | `Continue` | 1× (`RemoveDotSegments`) |

**Ação:** eliminar via flags de controle, inversão de condição, ou extração para helper com `Exit`.

---

### 🔴 C-3 — Memory Leak Confirmado — `Validation.Draft2019_09.pas`

Em `VisitContains`, quando `minContains` não existe no schema:

```pascal
LSchema := TJSONNumber.Create(1);  // criado mas nunca liberado
VisitMinContains(LSchema);
```

Nenhum `try..finally` libera este objeto. **Memory leak garantido** a cada chamada sem `minContains`.

---

### 🔴 C-4 — Memory Leak Potencial — `JsonSchema.pas`

No `TJsonSchema.Validate`, cada branch do `case` cria um visitor sem `try..finally`:

```pascal
LVisitorDraft6 := TDraft6Visitor.Create(...);
LWalker := TWalker<TDraft6Visitor>.Create(..., LVisitorDraft6); // se lançar → vaza
```

**Needs Confirmation:** verificar se `TWalker` assume ownership do visitor antes de adicionar `Free`.

---

### 🔴 C-5 — `TResource` é `record` com `TDictionary` interno — `Registry.Resource.pas`

`TResource` é um `record` com campos `FAnchors: TDictionary<string, TJSONValue>` e `FDynamicAnchors: TDictionary<string, TJSONValue>`. Quando o `TDictionary` pai que os contém é destruído, os dicionários internos **não são liberados** — `record` não tem destrutor.

**Ação:** converter `TResource` para `class` com `destructor Destroy`.

---

### 🔴 C-6 — Encoding corrompido — `Translate.ptBR.pas` e `Common.Utils.pas`

- JsonSchema.Translate.ptBR.pas: `TranslateUnsupportedVocabulary` exibe literalmente `vocabul?rio`, `n?o ? suportado` para o usuário final.
- JsonSchema.Common.Utils.pas: comentários com `?` no lugar de acentos (pode causar falha em ambientes com locale diferente).
- JsonSchema.Translate.enUS.pas: `??` em `TranslateInvalidType.Hint` (aspas tipográficas corrompidas).

---

### 🔴 C-7 — Constante duplicada no mesmo arquivo — `Validation.Draft2019_09.pas`

`CValidationKeywords` (array de 18 strings) declarada **duas vezes** no mesmo arquivo — em `VisitSchema` e em `VisitVocabulary`. Qualquer correção precisará ser aplicada nos dois lugares.

---

### 🔴 C-8 — Bug lógico: `Remove` chamado duas vezes — `Validation.Base.pas`

Em `LeaveRefResolution`:

```pascal
if SameText(LTopRef, AResolvedRef) then
  FRefResolutionStack.Pop
else
  FRefResolutionSet.Remove(AResolvedRef);  // Remove #1

FRefResolutionSet.Remove(AResolvedRef);    // Remove #2 — sempre executado, redundante no else
```

O segundo `Remove` é redundante no `else` — código morto que confunde.

---

### 🔴 C-9 — `RemoveDotSegments` usa `sLineBreak` como separador — `Registry.Utils.pas`

Em Windows `sLineBreak = #13#10`, e `TStringList.Text` normaliza quebras ao ler, podendo gerar segmentos vazios em paths como `//` ou deixar um `TrimRight` remover barras finais legítimas. Comportamento correto **por coincidência**, não por design.

**Ação:** substituir por `APath.Split(['/'])` determinístico.

---

### 🔴 C-10 — `case` sem `else` retorna `nil` — `Translate.Utils.pas`

`GetTranslation` não possui cláusula `else`: se um `TLanguage` novo for adicionado sem atualizar o método, retorna `nil`, causando `Access Violation` garantido.

---

### 🔴 C-11 — Auto-atribuições no-op — `Validation.Base.pas` / `Validation.Draft7.pas`

```pascal
InstanceNode := InstanceNode;                      // sem efeito
InstancePath := Format('%s', [InstancePath]);      // sem efeito
```

Linhas geradas por copiar blocos `with` que oculta o contexto real. Devem ser removidas.

---

## PARTE 2 — Débito Arquitetural

### Violações de NAMING (sistemáticas em todo o projeto)

| Violação | Impacto | Arquivos |
| --- | --- | --- |
| Prefixo `A` em parâmetros (deve ser `p`) | **Todo o projeto** — 20 arquivos | Sistemático |
| Prefixo `L` maiúsculo em variáveis locais (deve ser `l` minúsculo) | **Todo o projeto** | Sistemático |
| Classe `TranslateErrorAttribute` sem prefixo `T` | Médio | JsonSchema.Translate.Types.pas |
| Classe `VisitorKeywordAttribute` sem prefixo `T` | Médio | JsonSchema.Visitors.Types.pas |
| Enum `lang_enUS`/`lang_ptBR` com underscore (deve ser `langEnUS`) | Baixo | JsonSchema.Translate.Types.pas |
| Classe `TTranslate_enUS`/`TTranslate_ptBR` com underscore | Médio | JsonSchema.Translate.enUS.pas, JsonSchema.Translate.ptBR.pas |
| Alinhamento vertical de `:=` proibido | Cosmético mas sistemático | 10+ arquivos |
| Linhas >150 caracteres | Baixo | JsonSchema.Walker.Types.pas |
| Parâmetros de uma letra `A, B` | Médio | JsonSchema.Common.Utils.pas |

---

### Violações de SOLID

| Princípio | Violação | Arquivo | Severidade |
| --- | --- | --- | --- |
| **OCP** | `TJsonSchema.Validate` usa `case` que exige modificação para cada novo draft | JsonSchema.pas | 🟠 |
| **DIP** | `Validate` instancia visitors concretos diretamente | JsonSchema.pas | 🟠 |
| **SRP** | `TUtils` acumula: comparação JSON, regex, parsing de paths, normalização | JsonSchema.Common.Utils.pas | 🟠 |
| **SRP** | `TRegistryVisitor` acumula: resolução de URI, HTTP, mapeamento de arquivos locais, escopo | JsonSchema.Registry.Base.pas | 🔴 |
| **SRP** | `TWalker.Walk` (~120 linhas): detecta draft, executa precedência, itera keywords tudo junto | JsonSchema.Walker.pas | 🔴 |
| **SRP** | `VisitRef` (~280 linhas): 7 responsabilidades distintas | JsonSchema.Validation.Base.pas | 🔴 |
| **ISP** | `ITranslate` com 34 métodos não segregados | JsonSchema.Translate.Interfaces.pas | 🟡 |
| **ISP** | `IVisitor<T>` mistura visitantes, gerenciamento de escopo e rastreamento de keywords | JsonSchema.Visitors.Interfaces.pas | 🟠 |
| **OCP** | `TValidationWalker.New` e `GetTranslation` usam `case` rígido por entidade | JsonSchema.Walker.pas, JsonSchema.Translate.Utils.pas | 🟠 |

---

### Violações de DRY

| Duplicação | Arquivos | Severidade |
| --- | --- | --- |
| Bloco `LVisitorX / LWalker / Walk / Result` repetido 4× | JsonSchema.pas | 🟠 |
| `VisitContains`, `VisitDependencies`, `VisitPropertyNames` idênticos em Draft6, Draft7, Draft2019_09, Draft2020_12 | 4 arquivos Validation.Draft* | 🔴 |
| Loop JSON Pointer decode `~0`/`~1` duplicado | JsonSchema.Registry.Resource.pas + JsonSchema.Registry.Utils.pas | 🔴 |
| Bloco `NormalizeEvaluatedPropertyPath` duplicado 3× | JsonSchema.Validation.Base.pas | 🟠 |
| Bloco construção `LNewScope` duplicado 2× | JsonSchema.Registry.Base.pas | 🟠 |
| `CValidationKeywords` duplicado no mesmo arquivo | JsonSchema.Validation.Draft2019_09.pas | 🔴 |

---

### Violações de YAGNI

| Item | Arquivo | Descrição |
| --- | --- | --- |
| `TDraft6HyperSchemaVisitor` com 6 métodos vazios | JsonSchema.Validation.Draft6.pas | Stub especulativo sem uso |
| `TDraft7HyperSchemaVisitor` com 12 métodos vazios | JsonSchema.Validation.Draft7.pas | YAGNI severo |
| `IDraft2019_09HyperSchemaVisitor` sem GUID e sem implementação | JsonSchema.Validation.Draft2019_09.pas | Interface fantasma |
| `TURIReference.New` é alias puro de `From` | JsonSchema.Registry.Uri.pas | YAGNI — remover ou renomear |
| `FData` armazenado na base mas nunca lido | JsonSchema.Visitors.Base.pas | Campo fantasma |
| `VisitConst` override em Draft7 que só chama `inherited` | JsonSchema.Validation.Draft7.pas | Override sem valor |
| `IInterface` explícito na herança da interface | JsonSchema.Translate.Interfaces.pas | Redundante em Delphi |

---

### Violações de KISS

| Item | Arquivo |
| --- | --- |
| Double encoding em `WithCredentials` (`Encode` + `EncodingUserInfo`) | JsonSchema.Registry.Uri.Builder.pas |
| `RemoveDotSegments` com `sLineBreak`+`TrimRight` em vez de `Split(['/'])` | JsonSchema.Registry.Utils.pas |
| `if` duplo aninhado sem `begin..end` | JsonSchema.pas |
| `ParseAuthority` chamado 3× separadamente para `UserInfo`/`Host`/`Port` | JsonSchema.Registry.Uri.pas |
| `VisitRef` com 30 variáveis locais e 280 linhas | JsonSchema.Validation.Base.pas |

---

### Violações de Code Smells

| Smell | Arquivo | Detalhe |
| --- | --- | --- |
| Método Deus | JsonSchema.Validation.Base.pas | `VisitRef` ~280 linhas, 7 responsabilidades |
| Método Deus | JsonSchema.Walker.pas | `Walk` ~120 linhas, detecção + execução misturados |
| Código de teste em produção | JsonSchema.Registry.Base.pas | `TryResolveStaticMappedFile`, `IsLocalTestServerURI` com paths `localhost:1234` e caminhos de repositório |
| Código comentado inline | JsonSchema.Registry.Uri.pas, JsonSchema.Registry.Utils.pas | Código comentado com `//` no meio de implementação ativa |
| Contrato falso de imutabilidade | JsonSchema.Registry.Uri.pas | `TURIReference` documentada como imutável mas expõe setters `write` |
| `uricPort` não tratado no `case` | JsonSchema.Registry.Uri.Validator.pas | Enum não coberto — validação silenciosa |
| Mensagem de exceção sem i18n | JsonSchema.pas | `raise Exception.Create('Error in schema draft version selection')` |
| Erros ortográficos em ptBR | JsonSchema.Translate.ptBR.pas | `"possivel encontrar"`, `"esta correta"` |

---

## PARTE 3 — Roadmap de Refatoração (Priorizado)

### Sprint 1 — Bugs / Riscos Imediatos (não aguardar)

| # | Ação | Arquivo | Risco se não corrigir |
| --- | --- | --- | --- |
| 1 | Corrigir encoding corrompido em `TranslateUnsupportedVocabulary` | JsonSchema.Translate.ptBR.pas | Mensagem ilegível ao usuário |
| 2 | Corrigir `??` em `TranslateInvalidType.Hint` | JsonSchema.Translate.enUS.pas | Mensagem corrompida |
| 3 | Adicionar `try..finally` para `TJSONNumber.Create(1)` | JsonSchema.Validation.Draft2019_09.pas | Memory leak confirmado |
| 4 | Converter `TResource` para `class` | JsonSchema.Registry.Resource.pas | Memory leak de dicionários |
| 5 | Adicionar `else raise` no `case` de `GetTranslation` | JsonSchema.Translate.Utils.pas | `nil` → `Access Violation` |
| 6 | Corrigir erros ortográficos ptBR | JsonSchema.Translate.ptBR.pas | Qualidade do produto |
| 7 | Remover/corrigir auto-atribuições no-op | JsonSchema.Validation.Base.pas, JsonSchema.Validation.Draft7.pas | Confusão de leitura / bug latente |

### Sprint 2 — Violações de Padrão Críticas

| # | Ação | Impacto |
| --- | --- | --- |
| 8 | Eliminar todos os `with` (9 arquivos) | Legibilidade e manutenibilidade |
| 9 | Eliminar `Break` e `Continue` (5 arquivos) | Conformidade com padrões |
| 10 | Corrigir prefixo de parâmetros `A` → `p` e locais `L` → `l` | Consistência sistêmica |
| 11 | Renomear classes sem prefixo `T` | Conformidade Delphi |
| 12 | Remover alinhamento vertical de `:=` | Conformidade |
| 13 | Substituir `RemoveDotSegments` por `Split(['/'])` | Correção + clareza |

### Sprint 3 — DRY / Arquitetural

| # | Ação | Benefício |
| --- | --- | --- |
| 14 | Mover `VisitContains`/`VisitDependencies`/`VisitPropertyNames` para a classe base | Elimina ~200 linhas duplicadas entre 4 drafts |
| 15 | Extrair `DecodeJsonPointerSegment` como helper único | Elimina duplicação de decodificação `~0`/`~1` |
| 16 | Extrair `NormalizeEvaluatedPropertyPath` | Elimina 3 blocos idênticos em `VisitRef` |
| 17 | Extrair `VisitRef` em 3 métodos privados | Reduz método Deus de 280 → <80 linhas |
| 18 | Extrair `Walk` em `DetectDraftVersion`, `ProcessPrecedenceKeywords`, `ProcessRemainingKeywords` | Reduz método Deus de 120 → <40 linhas |
| 19 | Remover `CValidationKeywords` duplicada | 1 constante de nível de tipo |

### Sprint 4 — YAGNI / Limpeza

| # | Ação | Benefício |
| --- | --- | --- |
| 20 | Remover HyperSchemaVisitors com métodos todos vazios (Draft6, Draft7, 2019-09) | Remove ruído especulativo |
| 21 | Remover `TURIReference.New` (alias de `From`) | YAGNI |
| 22 | Remover `FData` da classe base se nunca lido | Campo fantasma |
| 23 | Remover `VisitConst` override vazio no Draft7 | YAGNI |
| 24 | Mover lógica de teste para fora de produção (`TryResolveStaticMappedFile`) | SRP + segurança de distribuição |

---

## Paridade de Tradução enUS ↔ ptBR

**Resultado estrutural: 34/34 métodos presentes em ambos os locales (100% de paridade estrutural).**

| Método | enUS | ptBR | Status |
| --- | --- | --- | --- |
| `TranslateUnsupportedVocabulary` | ✅ Correto | ❌ Encoding quebrado (`?`) | **Bug crítico** |
| `TranslateUnresolvedReference` | ✅ Correto | ⚠️ Erros ortográficos | Desvio gramatical |
| `TranslateInvalidType` | ⚠️ `??` na Hint | ✅ Correto | Bug de encoding no enUS |

---

## Análise do Padrão Visitor (Visitors/Walker)

O padrão Visitor está corretamente aplicado conceitualmente (walker percorre nós, despacha para o visitor por keyword via RTTI). No entanto:

- O despacho via `VisitorKeywordAttribute` + RTTI é elegante, porém o JsonSchema.Walker.pas `PopulateVisitorMethods` usa `Continue` 3× para filtrar atributos — padrão proibido.
- A interface `IVisitor<T>` mistura 3 responsabilidades distintas (ISP violado): agrupador de visitantes, gerenciador de escopo e rastreador de keywords.
- O pattern é canonicamente correto; os problemas são todos de implementação, não de design.
