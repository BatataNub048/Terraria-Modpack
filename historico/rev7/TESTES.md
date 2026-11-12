# Repetir verificações do instalador

Em Windows PowerShell 5.1, a partir da pasta extraída:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Installer.ps1
```

Isso executa os testes de código com arquivos temporários. Para incluir testes de todos os binários reais, passe -CachePath apontando para o cache criado pelo instalador (a pasta que contém steamcmd). Não use pastas de saves reais como fixtures. O script não simula clientes multiplayer nem testa FPS. Para o teste funcional, siga TESTE-INICIAL-MULTIPLAYER.txt.
