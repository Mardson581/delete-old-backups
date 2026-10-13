# Uso:
#   .\limpa-backup-antigo.ps1 -WhatIf   (simulação: mostra o que seria movido)
#   .\limpa-backup-antigo.ps1           (move os arquivos antigos para a lixeira)
#
# Para restaurar: mova a pasta de volta de $CaminhoLixeira\<data>\ para $CaminhoBackups.

[CmdletBinding(SupportsShouldProcess)]
param (
    [int]$LimiteDias = 4,
    [string]$CaminhoBackups = 'C:\BKP-Sistema',
    [string]$NomeArquivos = '*',
    # Nunca move os N arquivos mais recentes, mesmo que estejam acima do limite
    [int]$MinimoManter = 3,
    # Preferencialmente no mesmo volume de $CaminhoBackups (mover vira só um renomear)
    [string]$CaminhoLixeira = 'C:\BKP-Lixeira',
    # 0 = nunca exclui da lixeira automaticamente (esvazie manualmente)
    # >0 = exclui de vez os lotes que estão na lixeira há mais de N dias
    [int]$DiasLixeira = 5
)

$ErrorActionPreference = 'Stop'

function LogInfo {
    param ($Message)
    $dataHora = Get-Date -Format 'dd/MM/yyyy HH:mm'
    Write-Host "[$dataHora] [INFO] $Message" -ForegroundColor Blue
}

function LogWarning {
    param ($Message)
    $dataHora = Get-Date -Format 'dd/MM/yyyy HH:mm'
    Write-Host "[$dataHora] [WARNING] $Message" -ForegroundColor Yellow
}

if (-not (Test-Path -LiteralPath $CaminhoBackups -PathType Container)) {
    LogWarning -Message "Pasta de backups não encontrada: $CaminhoBackups. Abortando."
    exit 1
}

$falhas = 0

# Em outro volume, o Move-Item vira cópia + exclusão: mais lento e exige espaço livre
$raizBackups = [IO.Path]::GetPathRoot($CaminhoBackups)
$raizLixeira = [IO.Path]::GetPathRoot($CaminhoLixeira)
if ($raizBackups -ne $raizLixeira) {
    LogWarning -Message "A lixeira ($raizLixeira) está em outro volume que os backups ($raizBackups): mover será lento e exigirá espaço livre."
}

# --- 1) Move os arquivos antigos para a lixeira ---------------------------------

# A própria lixeira nunca entra na lista (caso esteja dentro de $CaminhoBackups)
$arquivos = @(
    Get-ChildItem -LiteralPath $CaminhoBackups -Filter $NomeArquivos |
        Where-Object { $_.FullName.TrimEnd('\') -ne $CaminhoLixeira.TrimEnd('\') } |
        Sort-Object CreationTime -Descending
)
LogInfo -Message "Foram encontradas $($arquivos.Count) arquivos em $CaminhoBackups"

$dataLimite = (Get-Date).AddDays(-$LimiteDias)
LogInfo -Message "Data limite: $($dataLimite.ToString('dd/MM/yyyy HH:mm'))"

# Protege as N mais recentes; entre as demais, pega só as mais velhas que o limite
$candidatas = @(
    $arquivos | Select-Object -Skip $MinimoManter | Where-Object { $_.CreationTime -le $dataLimite }
)

if ($candidatas.Count -eq 0) {
    LogInfo -Message 'Nenhuma pasta para mover.'
}
else {
    # Um lote por dia: C:\BKP-LIXO\2026-10-13\
    $loteDia = Join-Path $caminhoLixeira (Get-Date -Format 'yyyy-MM-dd')

    foreach ($arquivo in $candidatas) {
        if ($PSCmdlet.ShouldProcess($arquivos.FullName, "Mover para $loteDia")) {
            try {
                if (-not (Test-Path -LiteralPath $loteDia)) {
                    New-Item -ItemType Directory -Path $loteDia -Force | Out-Null
                }

                # Se já existir uma pasta com o mesmo nome no lote, acrescenta a hora
                $destino = Join-Path $loteDia $arquivo.Name
                if (Test-Path -LiteralPath $destino) {
                    $destino = Join-Path $loteDia ('{0}_{1}' -f $arquivos.Name, (Get-Date -Format 'HHmmss'))
                }

                LogWarning -Message "Movendo $($arquivo.Name) para a lixeira (criada em $($arquivo.CreationTime.ToString('dd/MM/yyyy HH:mm')))"
                Move-Item -LiteralPath $arquivo.FullName -Destination $destino
            }
            catch {
                $falhas++
                LogWarning -Message "Falha ao mover $($arquivo.Name): $($_.Exception.Message)"
            }
        }
    }
}

# --- 2) Esvazia da lixeira o que passou do prazo (opcional) --------------------

if ($DiasLixeira -gt 0 -and (Test-Path -LiteralPath $caminhoLixeira -PathType Container)) {
    $limiteLixeira = (Get-Date).Date.AddDays(-$DiasLixeira)

    foreach ($lote in Get-ChildItem -LiteralPath $caminhoLixeira -Directory) {
        # O nome do lote é a data em que foi para a lixeira (não depende de CreationTime)
        $dataLote = [datetime]::MinValue
        $ok = [datetime]::TryParseExact($lote.Name, 'yyyy-MM-dd',
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None, [ref]$dataLote)

        if (-not $ok) {
            LogWarning -Message "Ignorando '$($lote.Name)' na lixeira (nome fora do padrão yyyy-MM-dd)."
            continue
        }

        if ($dataLote -le $limiteLixeira -and $PSCmdlet.ShouldProcess($lote.FullName, 'Excluir definitivamente')) {
            try {
                LogWarning -Message "Excluindo definitivamente o lote $($lote.Name)"
                Remove-Item -LiteralPath $lote.FullName -Recurse -Force
            }
            catch {
                $falhas++
                LogWarning -Message "Falha ao excluir o lote $($lote.Name): $($_.Exception.Message)"
            }
        }
    }
}

if ($falhas -gt 0) {
    LogWarning -Message "$falhas operação(ões) falharam."
    exit 1
}
LogInfo -Message 'Concluído.'