@echo off
setlocal enableextensions enabledelayedexpansion
title Otimizador Windows 11
color 0B
set "LOG=%~dp0otimizar_log.txt"

:: Verificar privilegios de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [ERRO] Execute como ADMINISTRADOR.
    echo  Clique com botao direito no arquivo e escolha
    echo  "Executar como administrador"
    echo  Dica: copie o script para um disco local antes de executar.
    echo.
    pause
    exit /b 1
)

:: Garantir que a conta elevada e a mesma da sessao interativa
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; try { $sid=[System.Diagnostics.Process]::GetCurrentProcess().SessionId; $me=[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value; $shells=@(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'explorer.exe' -and $_.SessionId -eq $sid }); if (-not $shells) { exit 2 }; $users=@($shells | ForEach-Object { (Invoke-CimMethod -InputObject $_ -MethodName GetOwnerSid).Sid } | Where-Object { $_ }); if (-not $users) { exit 2 }; if ($users -contains $me) { exit 0 }; exit 1 } catch { [Console]::Error.WriteLine($_); exit 2 }" >nul 2>>"%LOG%"
if errorlevel 2 (
    echo.
    echo  [ERRO] Nao foi possivel confirmar a conta da sessao do Windows.
    echo  Inicie o script pela sua sessao interativa como administrador.
    >>"%LOG%" echo [ERRO] Falha ao identificar a conta da sessao interativa.
    pause
    exit /b 1
)
if errorlevel 1 (
    echo.
    echo  [ERRO] O script foi elevado com uma conta diferente da conta conectada.
    echo  Feche-o e execute novamente usando a sua propria conta no aviso do UAC.
    >>"%LOG%" echo [ERRO] Conta elevada diferente da conta da sessao interativa.
    pause
    exit /b 1
)

>>"%LOG%" echo.
>>"%LOG%" echo ##### Execucao iniciada em %date% %time% #####
>>"%LOG%" echo Usuario: %USERNAME%  Computador: %COMPUTERNAME%  Arquitetura: %PROCESSOR_ARCHITECTURE%
>>"%LOG%" ver
for %%v in (ProductName EditionID DisplayVersion CurrentBuildNumber UBR) do reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v %%v 2>nul | find "%%v" >>"%LOG%"
>>"%LOG%" echo Obs: build 22000 ou maior = Windows 11 ^(ProductName pode dizer Windows 10^).
>>"%LOG%" echo ----------------------------------------

:menu
cls
echo.
echo  =====================================================
echo   Otimizador Windows 11
echo   Alteracoes de usuario valem para a conta: %USERNAME%
echo  =====================================================
echo.
echo  Escolha uma acao:
echo   [1]  Criar ponto de restauracao (faca isto antes das demais)
echo   [2]  Desativar servicos (telemetria, Xbox, Fax, SysMain, WER, localizacao)
echo   [3]  Reduzir telemetria e desativar tarefas de rastreamento
echo   [4]  Remover apps pre-instalados e Xbox Game DVR (afeta jogos Xbox)
echo   [5]  Desativar Copilot, Recall, Click to Do e recursos de AI
echo   [6]  Alto desempenho, sem hibernacao/Fast Startup (nao p/ notebook)
echo   [7]  Reduzir animacoes e efeitos visuais
echo   [8]  Ocultar Widgets, Chat, sugestoes, apps promovidos e busca web
echo   [9]  Mostrar extensoes/arquivos ocultos e desativar AutoPlay
echo   [10] Negar permissoes de localizacao e diagnostico de apps
echo   [11] Impedir apps comuns (Fotos, Mapas, Camera etc.) em segundo plano
echo   [12] Apagar arquivos temporarios (usuario e sistema)
echo   [13] Reiniciar o computador
echo   [0]  Sair
echo.
set "opcao="
set /p "opcao=Digite o numero da opcao: "
set "opcao=!opcao: =!"
if "!opcao!"=="1" goto :restauracao
if "!opcao!"=="2" goto :servicos
if "!opcao!"=="3" goto :telemetria
if "!opcao!"=="4" goto :bloatware
if "!opcao!"=="5" goto :copilot
if "!opcao!"=="6" goto :energia
if "!opcao!"=="7" goto :visuais
if "!opcao!"=="8" goto :taskbar
if "!opcao!"=="9" goto :explorer
if "!opcao!"=="10" goto :permissoes
if "!opcao!"=="11" goto :apps_bg
if "!opcao!"=="12" goto :limpeza
if "!opcao!"=="13" goto :reiniciar
if "!opcao!"=="0" exit /b 0
echo.
echo  Opcao invalida. Tente novamente.
pause
goto :menu

:: ============================================================
:: PONTO DE RESTAURACAO
:: ============================================================
:restauracao
set "actionName=Ponto de restauracao"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Ponto de restauracao
echo.
echo --------------------------------------------------------
echo  Ponto de restauracao
echo --------------------------------------------------------
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $k='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'; $ok=1; try { Enable-ComputerRestore -Drive 'C:\'; New-ItemProperty -Path $k -Name SystemRestorePointCreationFrequency -Value 0 -PropertyType DWord -Force | Out-Null; Checkpoint-Computer -Description 'Ponto de Restauracao Pre-Otimizacao' -RestorePointType 'MODIFY_SETTINGS'; $ok=0 } catch { [Console]::Error.WriteLine($_) }; Remove-ItemProperty -Path $k -Name SystemRestorePointCreationFrequency -ErrorAction SilentlyContinue; exit $ok" 2>>"%LOG%" || set "actionFailed=1"
echo  Observacao: a Restauracao do Sistema nao reinstala apps removidos.
goto :action_done

:: ============================================================
:: SERVICOS
:: ============================================================
:servicos
set "actionName=Servicos"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Servicos
echo.
echo --------------------------------------------------------
echo  Servicos
echo --------------------------------------------------------
call :svc DiagTrack "DiagTrack - telemetria"
call :svc dmwappushsvc "dmwappushsvc - nao use em PC gerenciado por MDM/Intune"
call :svc SysMain "SysMain - Superfetch, prejudica HDD"
call :svc XblAuthManager "XblAuthManager - Xbox"
call :svc XblGameSave "XblGameSave - Xbox"
call :svc XboxNetApiSvc "XboxNetApiSvc - Xbox"
call :svc XboxGipSvc "XboxGipSvc - Xbox"
call :svc Fax "Fax"
call :svc WerSvc "Relatorio de erros do Windows"
call :svc RemoteRegistry "Registro remoto"
call :svc lfsvc "Geolocalizacao"
goto :action_done

:: ============================================================
:: TELEMETRIA
:: ============================================================
:telemetria
set "actionName=Telemetria e rastreamento"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Telemetria e rastreamento
echo.
echo --------------------------------------------------------
echo  Telemetria e rastreamento
echo --------------------------------------------------------
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" AllowTelemetry REG_DWORD 0
call :endstep "Telemetria no minimo - Home e Pro mantem o nivel Necessario"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" TailoredExperiencesWithDiagnosticDataEnabled REG_DWORD 0
call :endstep "Experiencias personalizadas"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" Enabled REG_DWORD 0
call :endstep "ID de publicidade"
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" EnableActivityFeed REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" PublishUserActivities REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" UploadUserActivities REG_DWORD 0
call :endstep "Historico de atividades"
call :reg "HKCU\SOFTWARE\Microsoft\Siuf\Rules" NumberOfSIUFInPeriod REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" DoNotShowFeedbackNotifications REG_DWORD 1
call :endstep "Notificacoes de feedback"
call :task "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
call :task "Microsoft\Windows\Application Experience\ProgramDataUpdater"
call :task "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
call :task "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
goto :action_done

:: ============================================================
:: APLICATIVOS PRE-INSTALADOS
:: ============================================================
:bloatware
set "actionName=Aplicativos pre-instalados e Game DVR"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Aplicativos pre-instalados e Game DVR
echo.
echo --------------------------------------------------------
echo  Aplicativos pre-instalados e Game DVR
echo --------------------------------------------------------
call :appx Microsoft.BingWeather "MSN Clima"
call :appx Microsoft.BingNews "MSN Noticias"
call :appx Microsoft.BingFinance "MSN Financas"
call :appx Microsoft.MicrosoftSolitaireCollection "Paciencia"
call :appx Microsoft.Microsoft3DViewer "Visualizador 3D"
call :appx Microsoft.MixedReality.Portal "Realidade Mista"
call :appx Microsoft.ZuneVideo "Filmes e TV"
call :appx Microsoft.People "Pessoas"
call :appx Microsoft.SkypeApp "Skype"
call :appx Clipchamp.Clipchamp "Clipchamp"
call :appx Microsoft.Getstarted "Primeiros Passos"
call :appx MicrosoftTeams "Teams consumer (legado)"
call :appx MSTeams "Microsoft Teams"
call :appx Microsoft.Todos "Microsoft To Do"
call :appx 7EE7776C.LinkedInforWindows "LinkedIn"
call :appx 5319275A.WhatsAppDesktop "WhatsApp"
call :appx Microsoft.BingSearch "Pesquisa do Microsoft Bing"
call :appx Microsoft.MicrosoftStickyNotes "Notas Autoadesivas"
call :appx Microsoft.WindowsFeedbackHub "Hub de Comentarios"
call :appx Microsoft.ZuneMusic "Reprodutor Multimidia"
call :appx Microsoft.OutlookForWindows "Novo Outlook"
call :appx Microsoft.MicrosoftOfficeHub "Office Hub"
call :appx Microsoft.Xbox.TCUI "Xbox TCUI"
call :appx Microsoft.XboxApp "Xbox App"
call :appx Microsoft.XboxGameOverlay "Xbox Game Overlay"
call :appx Microsoft.XboxGamingOverlay "Xbox Game Bar"
call :appx Microsoft.XboxIdentityProvider "Xbox Identity Provider"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" AppCaptureEnabled REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" AllowGameDVR REG_DWORD 0
call :endstep "Xbox Game DVR"
call :onedrive
goto :action_done

:: ============================================================
:: COPILOT E AI
:: ============================================================
:copilot
set "actionName=Copilot e recursos de AI"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Copilot e recursos de AI
echo.
echo --------------------------------------------------------
echo  Copilot e recursos de AI
echo --------------------------------------------------------
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" TurnOffWindowsCopilot REG_DWORD 1
call :reg "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" TurnOffWindowsCopilot REG_DWORD 1
call :endstep "Copilot - politica"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ShowCopilotButton REG_DWORD 0
call :endstep "Botao Copilot na barra de tarefas"
call :appx Microsoft.Copilot "Pacote Copilot"
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" DisableAIDataAnalysis REG_DWORD 1
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" AllowRecallEnablement REG_DWORD 0
call :endstep "Windows Recall"
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" DisableClickToDo REG_DWORD 1
call :endstep "Click to Do"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" IsDynamicSearchBoxEnabled REG_DWORD 0
call :endstep "Search Highlights"
echo  Observacao: o efeito depende da versao do Windows.
goto :action_done

:: ============================================================
:: PLANO DE ENERGIA
:: ============================================================
:energia
set "actionName=Plano de energia"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Plano de energia
echo.
echo --------------------------------------------------------
echo  Plano de energia
echo --------------------------------------------------------
:: Usar o alias oficial evita tentar duplicar um plano com o mesmo GUID.
powercfg /setactive SCHEME_MAX >>"%LOG%" 2>&1
if errorlevel 1 (
    >>"%LOG%" echo [AVISO] O plano Alto Desempenho nao esta disponivel ou nao pode ser ativado.
    set "stepFailed=1"
)
call :endstep "Plano Alto Desempenho"
powercfg /hibernate off >>"%LOG%" 2>&1
if errorlevel 1 set "stepFailed=1"
call :endstep "Hibernacao desativada"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" HiberbootEnabled REG_DWORD 0
call :endstep "Fast Startup desativado"
goto :action_done

:: ============================================================
:: EFEITOS VISUAIS
:: ============================================================
:visuais
set "actionName=Efeitos visuais"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Efeitos visuais
echo.
echo --------------------------------------------------------
echo  Efeitos visuais
echo --------------------------------------------------------
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" VisualFXSetting REG_DWORD 2
call :endstep "Modo Melhor desempenho"
call :reg "HKCU\Control Panel\Desktop" MenuShowDelay REG_SZ 0
call :endstep "Atraso dos menus zerado"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarAnimations REG_DWORD 0
call :endstep "Animacoes da barra de tarefas"
call :reg "HKCU\Software\Microsoft\Windows\DWM" EnableAeroPeek REG_DWORD 0
call :endstep "Aero Peek"
call :reg "HKCU\Control Panel\Desktop\WindowMetrics" MinAnimate REG_SZ 0
call :endstep "Animacao de minimizar e maximizar"
echo  Observacao: saia e entre na conta para aplicar tudo.
goto :action_done

:: ============================================================
:: BARRA DE TAREFAS E MENU INICIAR
:: ============================================================
:taskbar
set "actionName=Taskbar, menu Iniciar e busca"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Taskbar, menu Iniciar e busca
echo.
echo --------------------------------------------------------
echo  Taskbar, menu Iniciar e busca
echo --------------------------------------------------------
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Dsh" AllowNewsAndInterests REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarDa REG_DWORD 0
call :endstep "Widgets"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarMn REG_DWORD 0
call :endstep "Chat na barra de tarefas"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ShowTaskViewButton REG_DWORD 0
call :endstep "Botao Task View"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" SystemPaneSuggestionsEnabled REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" SubscribedContent-338388Enabled REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" SubscribedContent-338389Enabled REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" SilentInstalledAppsEnabled REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" SoftLandingEnabled REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" ScoobeSystemSettingEnabled REG_DWORD 0
call :endstep "Sugestoes, dicas e apps silenciosos"
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" DisableWindowsConsumerFeatures REG_DWORD 1
call :endstep "Apps promovidos reinstalados automaticamente"
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" HideRecommendedSection REG_DWORD 1
call :endstep "Secao Recomendados - so em algumas edicoes"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled REG_DWORD 0
call :reg "HKCU\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions REG_DWORD 1
call :endstep "Resultados da web na busca"
goto :action_done

:: ============================================================
:: EXPLORER E AUTOPLAY
:: ============================================================
:explorer
set "actionName=Explorer e AutoPlay"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Explorer e AutoPlay
echo.
echo --------------------------------------------------------
echo  Explorer e AutoPlay
echo --------------------------------------------------------
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" HideFileExt REG_DWORD 0
call :endstep "Extensoes de arquivo visiveis"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" Hidden REG_DWORD 1
call :endstep "Arquivos ocultos visiveis"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" DisableAutoplay REG_DWORD 1
call :endstep "AutoPlay desativado"
goto :action_done

:: ============================================================
:: PERMISSOES DE APPS
:: ============================================================
:permissoes
set "actionName=Permissoes de apps"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Permissoes de apps
echo.
echo --------------------------------------------------------
echo  Permissoes de apps
echo --------------------------------------------------------
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" Value REG_SZ Deny
call :endstep "Permissao de localizacao negada"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" Value REG_SZ Deny
call :endstep "Diagnostico de apps negado"
goto :action_done

:: ============================================================
:: APPS COMUNS EM SEGUNDO PLANO
:: ============================================================
:apps_bg
set "actionName=Apps comuns em segundo plano"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Apps comuns em segundo plano
echo.
echo --------------------------------------------------------
echo  Apps comuns em segundo plano
echo --------------------------------------------------------
echo  Apps nao instalados sao ignorados. Alarmes e Relogio nao e alterado.
echo.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; foreach ($n in 'Microsoft.Windows.Photos','Microsoft.WindowsCamera','Microsoft.WindowsMaps','Microsoft.WindowsCalculator','Microsoft.MicrosoftStickyNotes','Microsoft.WindowsFeedbackHub','Microsoft.GetHelp') { $p = @(Get-AppxPackage -Name $n); if ($p.Count -eq 0) { Write-Host (' ' + $n + ' ... nao instalado, ignorado'); continue }; foreach ($a in $p) { $k = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\' + $a.PackageFamilyName; New-Item -Path $k -Force | Out-Null; New-ItemProperty -Path $k -Name Disabled -Value 1 -PropertyType DWord -Force | Out-Null; New-ItemProperty -Path $k -Name DisabledByUser -Value 1 -PropertyType DWord -Force | Out-Null }; Write-Host (' ' + $n + ' ... desativado em segundo plano') }" 2>>"%LOG%" >"%TEMP%\otim_bg.txt" || set "actionFailed=1"
type "%TEMP%\otim_bg.txt"
type "%TEMP%\otim_bg.txt" >>"%LOG%"
del "%TEMP%\otim_bg.txt" >nul 2>&1
goto :action_done

:: ============================================================
:: LIMPEZA
:: ============================================================
:limpeza
set "actionName=Limpeza de arquivos temporarios"
set "actionFailed=0"
set "stepFailed=0"
>>"%LOG%" echo === %date% %time% - Limpeza de arquivos temporarios
echo.
echo --------------------------------------------------------
echo  Limpeza de arquivos temporarios
echo --------------------------------------------------------
if /i "%~dp0"=="%TEMP%\" (
    echo  [ERRO] O script esta dentro da pasta Temp. Mova-o antes de limpar.
    set "actionFailed=1"
    goto :action_done
)
echo  Arquivos em uso sao ignorados.
call :clean "%TEMP%" "Temp do usuario"
call :clean "%SystemRoot%\Temp" "Temp do sistema"
goto :action_done

:: ============================================================
:: REINICIAR
:: ============================================================
:reiniciar
echo.
choice /c SN /m " Reiniciar agora? Salve seus arquivos"
if errorlevel 2 goto :menu
shutdown /r /t 10 /c "Reiniciando para aplicar as otimizacoes"
echo  Reiniciando em 10 segundos. Para cancelar: shutdown /a
pause
goto :menu

:action_done
echo.
if "!actionFailed!"=="0" (
    echo  [SUCESSO] !actionName! concluido.
) else (
    echo  [FALHA] !actionName! terminou com um ou mais erros.
    echo  Detalhes no log: %LOG%
)
echo  Algumas mudancas so valem apos reiniciar ou sair e entrar na conta.
echo.
pause
goto :menu

:: ============================================================
:: FUNCOES AUXILIARES
:: ============================================================
:reg
>>"%LOG%" echo [REG] %~1 %2 = %4
reg add "%~1" /v %2 /t %3 /d %4 /f >>"%LOG%" 2>&1
if errorlevel 1 (
    set "stepFailed=1"
    >>"%LOG%" echo   -^> FALHOU
)
exit /b 0

:endstep
if "!stepFailed!"=="1" (
    echo  %~1 ... FALHOU
    set "actionFailed=1"
) else (
    echo  %~1 ... ok
)
set "stepFailed=0"
exit /b 0

:svc
>>"%LOG%" echo [SVC] %1
sc query %1 >nul 2>&1
if errorlevel 1 goto :svc_missing
sc config %1 start= disabled >>"%LOG%" 2>&1
if errorlevel 1 goto :svc_fail
sc query %1 | find "RUNNING" >nul 2>&1
if errorlevel 1 goto :svc_ok
net stop %1 /y >>"%LOG%" 2>&1
if errorlevel 1 echo  %~2 ... ainda em execucao ate reiniciar
:svc_ok
echo  %~2 ... desativado
>>"%LOG%" echo   -^> desativado
exit /b 0
:svc_missing
echo  %~2 ... nao existe neste Windows, ignorado
>>"%LOG%" echo   -^> nao existe, ignorado
exit /b 0
:svc_fail
echo  %~2 ... FALHOU
>>"%LOG%" echo   -^> FALHOU
set "actionFailed=1"
exit /b 0

:clean
>>"%LOG%" echo [CLEAN] %~1
del /s /f /q "%~1\*.*" >nul 2>&1
for /d %%i in ("%~1\*") do rd /s /q "%%i" >nul 2>&1
set "rest=0"
for /f %%n in ('dir /a-d /s /b "%~1" 2^>nul ^| find /c /v ""') do set "rest=%%n"
echo  %~2 ... limpa ^(!rest! arquivos em uso mantidos^)
>>"%LOG%" echo   -^> !rest! arquivos restantes ^(em uso^)
exit /b 0

:task
>>"%LOG%" echo [TASK] %~1
schtasks /query /tn "%~1" >nul 2>&1
if errorlevel 1 goto :task_missing
schtasks /change /tn "%~1" /disable >>"%LOG%" 2>&1
if errorlevel 1 goto :task_fail
echo  Tarefa %~nx1 ... desativada
exit /b 0
:task_missing
echo  Tarefa %~nx1 ... nao existe, ignorada
>>"%LOG%" echo   -^> nao existe, ignorada
exit /b 0
:task_fail
echo  Tarefa %~nx1 ... FALHOU
>>"%LOG%" echo   -^> FALHOU
set "actionFailed=1"
exit /b 0

:appx
>>"%LOG%" echo [APPX] %~1
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $n='%~1'; $failed=$false; $p=@(Get-AppxPackage -AllUsers -Name $n | Select-Object -ExpandProperty PackageFullName -Unique); $v=@(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $n -or $_.PackageName -like ($n+'_*') } | Select-Object -ExpandProperty PackageName -Unique); if (($p.Count + $v.Count) -eq 0) { exit 2 }; foreach ($full in $p) { try { Remove-AppxPackage -Package $full -AllUsers -ErrorAction Stop } catch { $left=@(Get-AppxPackage -AllUsers -Name $n | Where-Object PackageFullName -eq $full); if ($left.Count) { [Console]::Error.WriteLine('Falha ao remover pacote instalado '+$full+': '+$_.Exception.Message); $failed=$true } } }; foreach ($name in $v) { try { Remove-AppxProvisionedPackage -Online -PackageName $name -ErrorAction Stop | Out-Null } catch { $left=@(Get-AppxProvisionedPackage -Online | Where-Object PackageName -eq $name); if ($left.Count) { [Console]::Error.WriteLine('Falha ao remover provisionamento '+$name+': '+$_.Exception.Message); $failed=$true } } }; $remaining=@(Get-AppxPackage -AllUsers -Name $n); $provisioned=@(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $n -or $_.PackageName -like ($n+'_*') }); if (($remaining.Count + $provisioned.Count) -gt 0) { [Console]::Error.WriteLine('Pacote ainda presente apos a remocao: '+$n); $failed=$true }; if ($failed) { exit 1 }" >>"%LOG%" 2>&1
set "appxResult=!errorlevel!"
if "!appxResult!"=="2" (
    echo  %~2 ... nao instalado, ignorado
    >>"%LOG%" echo   -^> nao instalado, ignorado
    exit /b 0
)
if "!appxResult!"=="0" (
    echo  %~2 ... removido e verificado
    >>"%LOG%" echo   -^> removido e verificado
    exit /b 0
)
echo  %~2 ... FALHOU ^(codigo !appxResult!^)
>>"%LOG%" echo   -^> FALHOU, codigo !appxResult!
set "actionFailed=1"
exit /b 0

:onedrive
>>"%LOG%" echo [OneDrive] Aplicativo de sincronizacao
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $paths=@(($env:SystemRoot+'\SysWOW64\OneDriveSetup.exe'), ($env:SystemRoot+'\System32\OneDriveSetup.exe'), ($env:LOCALAPPDATA+'\Microsoft\OneDrive\Update\OneDriveSetup.exe'), ($env:LOCALAPPDATA+'\Microsoft\OneDrive\OneDriveSetup.exe')); $setup=$paths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1; if (-not $setup) { Write-Output '[OneDrive] Instalador nao encontrado nos caminhos conhecidos.'; exit 2 }; Write-Output ('[OneDrive] Instalador: '+$setup); Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2; try { $proc=Start-Process -FilePath $setup -ArgumentList '/uninstall' -WindowStyle Hidden -PassThru -Wait -ErrorAction Stop; Write-Output ('[OneDrive] Codigo de saida do desinstalador: '+$proc.ExitCode); if ($proc.ExitCode -eq -2147219813) { Write-Output '[OneDrive] Codigo especial conhecido como retorno de sucesso para esta operacao.'; exit 0 }; if ($proc.ExitCode -ne 0) { [Console]::Error.WriteLine('[OneDrive] O desinstalador retornou um codigo inesperado: '+$proc.ExitCode); exit 1 } } catch { [Console]::Error.WriteLine('[OneDrive] Nao foi possivel executar/aguardar o desinstalador: '+$_.Exception.Message); exit 1 }; Start-Sleep -Seconds 3; $running=@(Get-Process -Name OneDrive -ErrorAction SilentlyContinue); if ($running.Count -gt 0) { [Console]::Error.WriteLine('[OneDrive] O processo OneDrive continua em execucao apos a desinstalacao.'); exit 1 }; exit 0" <nul >>"%LOG%" 2>&1
set "onedriveResult=!errorlevel!"
if "!onedriveResult!"=="2" (
    echo  OneDrive ... instalador nao encontrado, ignorado
    >>"%LOG%" echo   -^> instalador nao encontrado, ignorado
    exit /b 0
)
if "!onedriveResult!"=="0" (
    echo  OneDrive - aplicativo, arquivos mantidos ... comando concluido
    >>"%LOG%" echo   -^> comando concluido sem erro; arquivos do usuario nao foram apagados
    exit /b 0
)
echo  OneDrive ... FALHOU ^(codigo !onedriveResult!^)
>>"%LOG%" echo   -^> FALHOU, codigo !onedriveResult!; consulte as mensagens acima
set "actionFailed=1"
exit /b 0
