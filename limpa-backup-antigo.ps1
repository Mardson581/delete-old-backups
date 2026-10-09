# O script exclui pastas que foram criadas a mais de 4 dias
# Ainda está em fase de testes e deve ser usado em ambiente isolado
# Para rodar o script use 'PowerShell.exe -ExecutionPolicy Bypass -File "<diretório do arquivo>\limpa-backup-antigo.ps1"
 
$LIMITE_DIAS = 4
 
# Função para mostrar uma messagem na tela com data e hora (útil para saber o que
# e quando aconteceu)
# Como usar: LogInfo -Message 'sua mensagem'
function LogInfo {
    param (
        $Message
    )
    Write-Host "[$(Get-Date -Format "dd/MM/yyyy HH:mm")] [INFO] $($Message)" -ForegroundColor "blue"
}
 
# Função para mostrar um aviso na tela com data e hora (útil para saber o que
# e quando aconteceu)
# Como usar: LogWarning -Message 'sua mensagem'
function LogWarning {
    param (
        $Message
    )
    Write-Host "[$(Get-Date -Format "dd/MM/yyyy HH:mm")] [WARNING] $($Message)" -ForegroundColor "yellow"
}
 
# Lista as pastas e salva o nome e data de criação de cada uma na variável 'pastas'
$pastas = Get-ChildItem -Directory | Sort-Object CreationTime | Select-Object Name, CreationTime
LogInfo -Message "Foram encontradas $($pastas.Length) pastas"
 
# Percorre cada pasta listada na variável 'pastas' e verifica se a data de criação
# foi a mais de 4 dias.
# O cálculo usa o dia atual (com o comando Get-Date), subtrai a quantidade $LIMITE_DIAS e compara se
# a pasta foi criada antes do dia resultante.
foreach ($pasta in $pastas) {
    if ($pasta.CreationTime -le (Get-Date).AddDays(-$LIMITE_DIAS)) {
        LogWarning -Message "A pasta $($pasta.Name) foi criada a mais de $($LIMITE_DIAS) dias"
    }
}

#msg.exe * "Isso foi chamado pelo TaskScheduler"