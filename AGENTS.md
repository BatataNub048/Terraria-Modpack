# Instruções para manutenção

- Use os manifests `rev8/profiles/*.lock.json` como referência dos cinco perfis e `historico/rev7/manifest.lock.json` para a Rev7. Preserve nomes internos, versões, IDs da Workshop, dependências, hashes e escolhas de perfil até o usuário pedir uma alteração funcional.
- Mantenha `rev8/configuracoes/<perfil>` como retrato dos ajustes auditados. Atualizações de configuração devem explicar o motivo e o efeito sobre a campanha. A preparação pelos launchers usa os presets dos manifests.
- Preserve as convenções de caminhos dos launchers e o suporte a PowerShell 5.1. Teste sintaxe e valide a seleção e dependências do perfil quando alterar instalação ou manifests. Em testes de jogo, use cópias descartáveis separadas de mundos, personagens e dados auxiliares.
- Use os relatórios existentes para identificar versões realmente testadas. Registre cenário, versão e resultado medido ao atualizar documentação. Diferencie carregamento, geração, desempenho e compatibilidade multiplayer.
- Mantenha binários, saves, backups, logs, caches, credenciais, caminhos pessoais e material de terceiros sem autorização fora do Git. Registre a origem e as condições de redistribuição ao propor novos patches.
- Confira a lista do `git diff --cached` antes de publicar e examine arquivos novos em busca de dados sensíveis. Preserve o histórico remoto e aplique o fluxo de revisão solicitado pelo usuário.
