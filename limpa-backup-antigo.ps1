# Uso:
#   .\limpa-backup-antigo.ps1 -WhatIf     (simulação: mostra o que seria excluído)
#   .\limpa-backup-antigo.ps1             (exclui de verdade)

[CmdletBinding(SupportsShouldProcess)]
param (
    [int]$LimiteDias = 4,
    [string]$CaminhoBackups = 'C:\Backups',
    [string]$NomePastas = 'Backup*',
    # Nunca exclui as N pastas mais recentes, mesmo que estejam acima do limite
    [int]$MinimoManter = 3
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

# Aborta se a pasta de backups não existir (evita agir no diretório errado)
if (-not (Test-Path -LiteralPath $CaminhoBackups -PathType Container)) {
    LogWarning -Message "Pasta de backups não encontrada: $CaminhoBackups. Abortando."
    exit 1
}

# Lista as pastas de backup, da mais nova para a mais antiga
$pastas = @(
    Get-ChildItem -LiteralPath $CaminhoBackups -Directory -Filter $NomePastas |
        Sort-Object CreationTime -Descending
)
LogInfo -Message "Foram encontradas $($pastas.Count) pastas em $CaminhoBackups"

$dataLimite = (Get-Date).AddDays(-$LimiteDias)
LogInfo -Message "Data limite: $($dataLimite.ToString('dd/MM/yyyy HH:mm'))"

# Protege as N mais recentes; entre as demais, pega só as mais velhas que o limite
$candidatas = @(
    $pastas | Select-Object -Skip $MinimoManter | Where-Object { $_.CreationTime -le $dataLimite }
)

if ($candidatas.Count -eq 0) {
    LogInfo -Message 'Nada para excluir.'
    exit 0
}

$falhas = 0
foreach ($pasta in $candidatas) {
    if ($PSCmdlet.ShouldProcess($pasta.FullName, 'Excluir pasta de backup')) {
        try {
            LogWarning -Message "Excluindo $($pasta.Name) (criada em $($pasta.CreationTime.ToString('dd/MM/yyyy HH:mm')))"
            Remove-Item -LiteralPath $pasta.FullName -Recurse -Force
        }
        catch {
            $falhas++
            LogWarning -Message "Falha ao excluir $($pasta.Name): $($_.Exception.Message)"
        }
    }
}

if ($falhas -gt 0) {
    LogWarning -Message "$falhas pasta(s) não puderam ser excluídas."
    exit 1
}
LogInfo -Message 'Limpeza concluída.'
