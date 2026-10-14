# Limpeza de backups antigos

Automação em PowerShell para limpar backups antigos em duas etapas, usando uma lixeira própria:

1. **`limpa-backup-antigo.ps1`** move os itens que ultrapassam um limite de dias para uma pasta separada (a lixeira).
2. **`apaga-lixeira-backups.ps1`** exclui definitivamente o que está na lixeira há mais de N dias.

Assim, uma exclusão indevida ainda pode ser desfeita enquanto o item estiver na lixeira.

## Como funciona

- Os itens de `CaminhoBackups` são ordenados pela data de criação (`CreationTime`).
- Os `MinimoManter` mais recentes **nunca** são movidos, mesmo que estejam acima do limite. Isso protege contra o caso de o job de backup parar de rodar.
- Entre os demais, os que têm data de criação igual ou anterior a `LimiteDias` dias atrás vão para `<CaminhoLixeira>\AAAA-MM-DD\`, onde a data é o dia em que foram movidos.
- O segundo script exclui os lotes (`AAAA-MM-DD`) com mais de `DiasLixeira` dias. Subpastas da lixeira fora do padrão de data são ignoradas, com um aviso.
- Se já existir um item com o mesmo nome no lote do dia, o horário (`HHmmss`) é acrescentado ao nome.
- Os dois scripts aceitam `-WhatIf` (simulação).
- Código de saída: `0` em sucesso; `1` se algo falhou ou se a pasta de backups não existe.

## Parâmetros

### `limpa-backup-antigo.ps1`

| Parâmetro        | Padrão           | Descrição                                                                                                 |
| ---------------- | ---------------- | --------------------------------------------------------------------------------------------------------- |
| `LimiteDias`     | `4`              | Dias de retenção. Itens com data de criação igual ou anterior à data limite vão para a lixeira.           |
| `CaminhoBackups` | `C:\BKP-Sistema` | Diretório que contém os backups.                                                                          |
| `NomeArquivos`   | `*`              | Filtro (curinga) dos itens considerados na limpeza, por exemplo `Backup-Dia-*`.                           |
| `MinimoManter`   | `3`              | Quantidade de itens mais recentes que nunca são movidos, independentemente da idade.                      |
| `CaminhoLixeira` | `C:\BKP-Lixeira` | Pasta que recebe os itens movidos. Prefira o mesmo volume de `CaminhoBackups` (veja "Observações").        |

### `apaga-lixeira-backups.ps1`

| Parâmetro        | Padrão           | Descrição                                                                                                  |
| ---------------- | ---------------- | ---------------------------------------------------------------------------------------------------------- |
| `CaminhoLixeira` | `C:\BKP-Lixeira` | Mesma pasta usada como lixeira pelo `limpa-backup-antigo.ps1`. Deve ser igual nos dois scripts.            |
| `DiasLixeira`    | `4`              | Lotes com mais de N dias na lixeira são excluídos definitivamente. `0` desativa a exclusão automática.     |

## Exemplos

Simulação (não move nada, só mostra o que seria feito):

```powershell
.\limpa-backup-antigo.ps1 -WhatIf
```

Execução com as configurações padrão:

```powershell
.\limpa-backup-antigo.ps1
.\apaga-lixeira-backups.ps1
```

Execução com parâmetros personalizados:

```powershell
.\limpa-backup-antigo.ps1 -LimiteDias 3 -CaminhoBackups 'D:\Dados\Backups' -NomeArquivos 'Backup-Dia-*' -MinimoManter 3 -CaminhoLixeira 'D:\Lixeira' -WhatIf
.\apaga-lixeira-backups.ps1 -CaminhoLixeira 'D:\Lixeira' -DiasLixeira 10 -WhatIf
```

## Restaurar um item

Mova o item de volta de `<CaminhoLixeira>\AAAA-MM-DD\` para `CaminhoBackups`. Isso só é possível enquanto o lote ainda não tiver sido excluído pelo segundo script.

## Deploy

No Windows, use o Agendador de Tarefas. Crie **uma tarefa para cada script**, com o de limpeza rodando antes do de exclusão (por exemplo, às 02:00 e às 02:30).

1. **Ação:** `Iniciar um programa`
2. **Programa/script:** `powershell.exe`
3. **Adicione argumentos:**

   ```
   -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "C:\Scripts\limpa-backup-antigo.ps1"
   ```

   Para o segundo script, troque o caminho por `apaga-lixeira-backups.ps1`.

Se usar parâmetros personalizados, acrescente-os depois do caminho do script, por exemplo `-LimiteDias 5 -NomeArquivos "Backup_*"`. Se mudar `-CaminhoLixeira` em uma tarefa, mude também na outra.

Cuidados:

- Use `-WhatIf` apenas para testar; remova-o da tarefa definitiva.
- A conta que executa a tarefa precisa de permissão de modificação em `CaminhoBackups` e em `CaminhoLixeira`.
- O código de saída `1` aparece no histórico da tarefa e permite detectar falhas.

## Observações

- **Mesmo volume.** Com a lixeira no mesmo volume dos backups, mover é só um renomear: instantâneo e sem gastar espaço extra. Em outro volume vira cópia + exclusão, o que é lento e exige espaço livre (o script avisa). O espaço em disco só é liberado quando o segundo script exclui o lote.
- **Retenção total.** Um item fica, no total, cerca de `LimiteDias + DiasLixeira` dias antes de ser excluído de vez.
- **`CreationTime`.** Pastas ou arquivos copiados ou restaurados ganham uma data de criação nova e podem ser tratados como recentes. Considere isso se seus backups são copiados de outro lugar.
- **Caminhos.** Aceitam `\` e `/`, mas prefira `\`.
- **Codificação.** Mantenha os `.ps1` salvos em UTF-8 **com BOM**. Sem o BOM, o Windows PowerShell 5.1 (padrão no Windows Server) exibe os acentos das mensagens de forma incorreta.