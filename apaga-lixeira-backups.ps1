[CmdletBinding(SupportsShouldProcess)]
param (
    # Preferencialmente no mesmo volume de $CaminhoBackups (mover vira só um renomear)
    [string]$CaminhoLixeira = 'C:\BKP-Lixeira'
    # 0 = nunca exclui da lixeira automaticamente (esvazie manualmente)
    # >0 = exclui de vez os lotes que estão na lixeira há mais de N dias
    [int]$DiasLixeira = 4
)

function LogWarning {
    param ($Message)
    $dataHora = Get-Date -Format 'dd/MM/yyyy HH:mm'
    Write-Host "[$dataHora] [WARNING] $Message" -ForegroundColor Yellow
}

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