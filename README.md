
# Limpeza de backups antigos

Script em Powershell para automatizar a limpeza de backups antigos, movendo aqueles que ultrapassam um limite de dias configurável para uma pasta separada.


## Como usar

| Parâmetro | Padrão     | Descrição                |
| :-------- | :------- | :------------------------- |
| `LimiteDias` | 4 | Número de dias de retenção. Pastas com data de criação igual ou anterior à data limite são elegíveis para a lixeira |
`CaminhoBackups`| C:\BKP-Sistema | Caminho do diretório que contém as pastas de backup. |
`NomeArquivos` | * | Filtro utilizado para identificar as pastas que serão consideradas na limpeza. |
`MinimoManter` | 3 | Quantidade de pastas mais recentes que devem ser preservadas, independentemente da idade. |
## Exemplos

#### Rodar em modo de simulação (não apaga nenhuma pasta, apenas indica)
```powershell
.\limpa-backup-antigo.ps1 -WhatIf
```

##### Executar a limpeza com as configurações padrão
```powershell
.\limpa-backup-antigo.ps1
```

##### Executar com parâmetros personalizados
```powershell
.\limpa-backup-antigo.ps1 -LimiteDias 3 -CaminhoBackups 'D:/Dados/Backups' -NomePastas 'Backup-Dia-*' -MinimoManter 3 -CaminhoLixeira "D:/Lixeira" -DiasLixeira 10 -WhatIf
```


# Deploy
No Windows, pode-se usar o agendador de tarefas para executar o script automaticamente. Use as seguintes configurações:

#### 1. Ação (Action): `Iniciar um programa`
#### 2. Programa/script: `powershell.exe`
#### 3. Adicione argumentos: `-ExecutionPolicy Bypass -File "Caminho do script"`.
Se as configurações personalizadas do script forem usadas (-Whatif, -NomePastas, -LimiteDias, etc), adicione cada uma delas após o caminho do script. Exemplo `-ExecutionPolicy Bypass -File "Caminho do script" -LimiteDias 5 -NomePastas "Backup_*"`