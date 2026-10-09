## Configurações ##
$LIMITE_DIAS = 4
$CAMINHO_BACKUPS = 'C:\Backups'
$NOME_PASTAS = "Backup*"
 
# Função para mostrar uma messagem na tela com data e hora (útil para saber o que
# e quando aconteceu)
# Como usar: LogInfo -Message 'sua mensagem'
function LogInfo {
    param (
        $Message
    )
    $dataHora = Get-Date -Format 'dd/MM/yyyy HH:mm'
    Write-Host "[$dataHora] [INFO] $Message" -ForegroundColor "blue"
}
 
# Função para mostrar um aviso na tela com data e hora (útil para saber o que
# e quando aconteceu)
# Como usar: LogWarning -Message 'sua mensagem'
function LogWarning {
    param (
        $Message
    )
    $dataHora = Get-Date -Format 'dd/MM/yyyy HH:mm'
    Write-Host "[$dataHora] [WARNING] $($Message)" -ForegroundColor "yellow"
}
 
# Lista as pastas e salva cada uma na variável 'pastas'
$pastas = @(Get-ChildItem -Directory -Filter $NOME_PASTAS)
LogInfo -Message "Foram encontradas $($pastas.Length) pastas"
 
# Percorre cada pasta listada na variável 'pastas' e verifica se a data de criação
# foi a mais de 4 dias.
# O cálculo usa o dia atual (com o comando Get-Date), subtrai a quantidade $LIMITE_DIAS e compara se
# a pasta foi criada antes do dia resultante.
$dataLimite = (Get-Date).AddDays(-$LIMITE_DIAS)
LogInfo -Message "Data limite: $($dataLimite.ToString('dd/MM/yyyy HH:mm'))"

foreach ($pasta in $pastas) {
    if ($pasta.CreationTime -le $dataLimite) {
        LogWarning -Message "A pasta $($pasta.Name) foi criada a mais de $LIMITE_DIAS dias. Excluindo..."
        Remove-Item -LiteralPath $pasta.FullName -Recurse -Force
    }
}