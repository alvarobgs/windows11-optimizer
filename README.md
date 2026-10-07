# Windows 11 Optimizer

Script em lote (`.bat`) com menu interativo para otimizar o Windows 11: remove apps pre-instalados, reduz telemetria e rastreamento e desativa recursos que costumam causar lentidao.

Cada acao e independente. Voce escolhe pelo numero, o script mostra o resultado e volta ao menu.

> **Aviso:** o script altera servicos, registro e apps do sistema. Teste antes em uma maquina secundaria ou virtual e crie um ponto de restauracao (opcao 1). A Restauracao do Sistema **nao reinstala apps removidos**.
> O script foi escrito para o Windows 11. No Windows 10 ele funciona, mas varias opcoes nao tem efeito (veja "Compatibilidade").

## Requisitos

- Windows 11 (Windows 10 parcialmente)
- Executar como **Administrador**
- PowerShell (ja incluido no Windows)

## Como usar

### Opcao 1: baixar e executar

1. Baixe [`otimizar_windows11.bat`](https://raw.githubusercontent.com/alvarobgs/windows11-optimizer/main/otimizar_windows11.bat) (ou clone o repositorio).
2. Salve em um disco **local**, por exemplo `C:\Otimizador\`. Nao execute de uma pasta de rede nem da pasta Temp.
3. Clique com o botao direito no arquivo e escolha **Executar como administrador**.
4. Digite o numero da opcao e pressione Enter. Ao terminar, pressione uma tecla para voltar ao menu.
5. Use a opcao **13** para reiniciar ao final.

### Opcao 2: executar direto do GitHub pelo PowerShell

Um `.bat` nao pode ser executado diretamente com `irm ... | iex`, porque o `iex` interpreta PowerShell e nao batch. O comando abaixo baixa o arquivo para uma pasta do seu perfil e o executa. Ele grava o arquivo no disco, mas apenas temporariamente.

Abra o **PowerShell como Administrador** e execute:

```powershell
$d = "$env:USERPROFILE\Otimizador"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/alvarobgs/windows11-optimizer/main/otimizar_windows11.bat" -OutFile "$d\otimizar_windows11.bat"; cmd /c "$d\otimizar_windows11.bat"
```

Observacoes:

- O PowerShell precisa estar **elevado**, senao o script exibe o erro de administrador.
- Nao use a pasta Temp como destino: a opcao 12 se recusa a limpar se o script estiver la.
- Leia o codigo antes de executar. Executar scripts da internet sem revisar e um risco, inclusive este.

## Menu

| Opcao | O que faz |
|---|---|
| 1 | Cria um ponto de restauracao do sistema (contorna o limite de 1 por 24 horas). |
| 2 | Desativa servicos: DiagTrack, dmwappushsvc, SysMain, Xbox (XblAuthManager, XblGameSave, XboxNetApiSvc, XboxGipSvc), Fax, WerSvc, RemoteRegistry e lfsvc (localizacao). |
| 3 | Reduz telemetria (politica `AllowTelemetry`), ID de publicidade, experiencias personalizadas, historico de atividades e notificacoes de feedback. Desativa tarefas agendadas do Compatibility Appraiser, ProgramDataUpdater e CEIP. |
| 4 | Remove apps pre-instalados (veja a lista abaixo) e desativa o Xbox Game DVR. |
| 5 | Desativa Copilot (politica, botao e pacote), Recall, Click to Do, analise de dados por IA e Search Highlights. |
| 6 | Ativa o plano Alto Desempenho, desativa a hibernacao e o Fast Startup. |
| 7 | Reduz efeitos visuais: modo "Melhor desempenho", atraso de menus zerado, animacoes da barra de tarefas e de janelas, Aero Peek. |
| 8 | Oculta Widgets, Chat, Task View e a secao Recomendados do Iniciar. Desativa sugestoes, dicas, apps promovidos instalados em silencio e resultados da web na busca. |
| 9 | Mostra extensoes de arquivo e arquivos ocultos. Desativa o AutoPlay. |
| 10 | Nega as permissoes globais de localizacao e de diagnostico de apps. |
| 11 | Impede Fotos, Camera, Mapas, Calculadora, Sticky Notes, Hub de Comentarios e Obter Ajuda de rodar em segundo plano. Alarmes e Relogio e o Gravador de Voz nao sao alterados. |
| 12 | Apaga arquivos temporarios do usuario e do sistema. Arquivos em uso sao mantidos. |
| 13 | Reinicia o computador (confirmacao e 10 segundos para cancelar com `shutdown /a`). |
| 0 | Sai. |

### Apps removidos (opcao 4)

Clima, Noticias e Financas (MSN), Paciencia, Visualizador 3D, Realidade Mista, Filmes e TV, Pessoas, Skype, Clipchamp, Primeiros Passos, Teams (consumer), novo Outlook, Office Hub e os apps Xbox (TCUI, App, Game Overlay, Game Bar e Identity Provider). O Copilot e removido pela opcao 5.

Alem de remover o app do usuario atual, o script tambem remove o pacote pre-instalado, para que ele nao volte em novos perfis nem apos atualizacoes.

## Resultado e log

- Cada acao mostra `ok`, `FALHOU` ou `ignorado` (item que nao existe nesta versao do Windows) e termina com **[SUCESSO]** ou **[FALHA]**.
- Um arquivo `otimizar_log.txt` e gravado **na mesma pasta do script**. Ele contem a versao do Windows (build e edicao), cada item alterado e as mensagens de erro reais.
- Se algo falhar, envie o log ao reportar um problema.

## Pontos de atencao

- **Contas:** as configuracoes de usuario (visuais, barra de tarefas, apps em segundo plano) valem apenas para a conta que executa o script. O cabecalho do menu mostra qual e.
- **Xbox:** remover os apps e servicos Xbox pode quebrar o login em jogos da Microsoft Store e o Game Pass.
- **Notebook:** o plano Alto Desempenho e a hibernacao desativada (opcao 6) aumentam o consumo de bateria. Em HD, desativar o SysMain pode piorar o desempenho.
- **MDM/Intune:** nao use a opcao 2 em PCs gerenciados, pois ela desativa o `dmwappushsvc`.
- **Telemetria:** no Windows Home e Pro o nivel minimo permitido e "Necessario". O valor 0 so e respeitado no Enterprise e no Education.
- **Politicas:** algumas chaves de politica fazem as Configuracoes exibirem "Algumas configuracoes sao gerenciadas pela sua organizacao".
- **Reinicio:** varias mudancas so valem depois de reiniciar ou sair e entrar na conta.
- **Nomes de pacotes:** alguns nomes de apps nao foram confirmados na documentacao oficial. Se um nao existir, o script mostra "ignorado".

## Compatibilidade

- **Windows 11:** alvo do script. A eficacia de algumas politicas (Copilot, Recall, Click to Do, Recomendados) depende da edicao e da versao.
- **Windows 10 22H2:** testado em um notebook. As opcoes de servicos, telemetria, apps, visuais, Explorer e limpeza funcionaram. As opcoes especificas do Windows 11 (Chat, Recomendados, Recall, Click to Do, botao Copilot) gravam chaves sem efeito.

## Desfazendo alteracoes

O script nao possui opcao de reverter. Para desfazer:

- **Servicos:** reative em `services.msc` ou com `sc config <nome> start= auto`.
- **Registro:** apague ou altere as chaves listadas no `otimizar_log.txt`.
- **Apps:** reinstale pela Microsoft Store.
- **Hibernacao:** `powercfg /hibernate on`.

## Licenca

Uso por sua conta e risco. Sem garantias.
