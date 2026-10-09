# delete-old-backups
Automação em Powershell para remover pastas criadas até uma data definida dentro de um diretório.
O script exclui pastas que foram criadas a mais de 4 dias (ou definido no código). Ainda está em fase de testes e deve ser usado em ambiente isolado

# Como usar
Para rodar o script use 'PowerShell.exe -ExecutionPolicy Bypass -File "<diretório do arquivo>\limpa-backup-antigo.ps1"