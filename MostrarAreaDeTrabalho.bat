@echo off
setlocal
chcp 65001 >nul
title Configurar Mostrar Area de Trabalho

set "PASTA=%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
set "SCF=%PASTA%\Mostrar Área de Trabalho.SCF"
set "EXE=%USERPROFILE%\Desktop\Mostrar Área de Trabalho.exe"

echo.
echo ==========================================
echo   Mostrar Area de Trabalho - Configuracao
echo ==========================================
echo.

:: 1. Criar a pasta, caso necessario
if not exist "%PASTA%" mkdir "%PASTA%"

if not exist "%PASTA%" (
    echo ERRO: Nao foi possivel criar a pasta.
    pause
    exit /b 1
)

:: 2. Criar o arquivo SCF
(
    echo [Shell]
    echo Command=2
    echo IconFile=explorer.exe,3
    echo [Taskbar]
    echo Command=ToggleDesktop
) > "%SCF%"

if not exist "%SCF%" (
    echo ERRO: Falha ao criar o arquivo SCF.
    pause
    exit /b 1
)

:: 3. Criar o EXE vazio na area de trabalho
type nul > "%EXE%"

if not exist "%EXE%" (
    echo ERRO: Falha ao criar o arquivo EXE.
    pause
    exit /b 1
)

echo Arquivos criados:
echo "%SCF%"
echo "%EXE%"
echo.
echo PROXIMA ETAPA:
echo 1. Fixe "Mostrar Área de Trabalho.exe"
echo    na barra de tarefas.
echo 2. Volte para esta janela.
echo.
pause

:: 4. Localizar e alterar o destino do atalho fixado
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
 "$dir = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar';" ^
 "$target = Join-Path $dir 'Mostrar Área de Trabalho.SCF';" ^
 "$ws = New-Object -ComObject WScript.Shell;" ^
 "if (-not (Test-Path -LiteralPath $target)) { Write-Host 'ERRO: Arquivo SCF nao encontrado:' $target; exit 3 };" ^
 "$links = @(Get-ChildItem -LiteralPath $dir -Filter '*.lnk' -ErrorAction SilentlyContinue);" ^
 "$link = $links | Where-Object { $_.BaseName -like '*Mostrar*Área de Trabalho*' } | Select-Object -First 1;" ^
 "if (-not $link) { Write-Host 'Atalho fixado nao encontrado.'; Write-Host 'Pasta pesquisada:' $dir; Write-Host 'Atalhos encontrados:'; if ($links.Count -eq 0) { Write-Host '(Nenhum arquivo LNK encontrado)' } else { $links | ForEach-Object { Write-Host $_.Name } }; exit 2 };" ^
 "try { $s = $ws.CreateShortcut($link.FullName); $s.TargetPath = $target; $s.Arguments = ''; $s.WorkingDirectory = $dir; $s.IconLocation = $env:WINDIR + '\System32\SHELL32.dll,34'; $s.Save(); Write-Host 'Destino do atalho atualizado com sucesso:'; Write-Host $link.FullName; } catch { Write-Host 'ERRO ao atualizar o atalho:' $_.Exception.Message; exit 4 }"

set "RESULTADO=%ERRORLEVEL%"

if not "%RESULTADO%"=="0" (
    echo.
    echo Nao foi possivel atualizar o atalho automaticamente.
    echo Consulte as mensagens acima para identificar o problema.
    echo.
    pause
    exit /b 1
)

echo.
echo Procedimento concluido!
echo.
echo Teste o atalho na barra de tarefas.
echo.
pause
endlocal