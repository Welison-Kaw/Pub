@rem Welison da Silva
@echo off > NUL
chcp 65001
setlocal enableDelayedExpansion
title Publicacao + Backup (%username%)

(set \n=^
%=Do not remove this line=%
)
set /A vErro=0
set /A vSilent=0
set /A vRollback=0
set paramAux=%*

set diretorio=%~dp0

cls
echo.
echo Publicador
echo ----------
echo.
echo.

rem Lê parametros
set paramAux=%paramAux:-=%
for %%a in (%*) do (
	if %%a==--help (
		goto :param_%%a
	)
	set param=%%a
	if "!param:~0,1!"=="-" (
		if not "!param:s=!"=="!param!" (
			set /A vSilent=1
			set paramAux=!paramAux:s=!
		)

		if not "!param:r=!"=="!param!" (
			set /A vRollback=1
			set paramAux=!paramAux:r=!
		)

		rem Valição pra saber se não existem parametros inválidos
		if not "!paramAux!"=="" (
			set /A vErro=3
			call :fim 3
			goto :eof
		)
	)
)

call :testeConfig
call :leConfig
call :showListaApps

set /a index=%index%-1

call :fazBackup
call :publica

rem if vRollback==0 (
rem 	call :fazBackup
rem 	call :publica
rem ) else (
rem 	call :listaVersoes
rem 	call :fazRollback
rem )

call :fim %vErro%
goto :eof

rem Verifica se existe arquivo de config
:testeConfig
	if not exist "%diretorio%\pubsettings.ini" (
		set /A vErro=1
	) 
exit /b

rem Lê arquivo de config e pede Apps
:leConfig
	for /f "tokens=1,2 delims==" %%G in (%diretorio%\pubsettings.ini) do set %%G=%%H

	rem Direciona para a pasta
	pushd %source%
	set /p listaApps=Aplicacoes: 
	popd

	echo.
	echo.
exit /b

:showListaApps
	set index=0
	for %%A in (%listaApps%) do (
		if not exist %source%%%A (
			set /a vErro=2
		) else (
			set App[!index!]=%%A
		)
		rem if "!vErro!"=="0" (
		rem 	set App[!index!] = %%A
		rem ) else (
		rem 	rem set AllApp[!index!] = %%A !\n!
		rem )
		set /a index += 1
	)
	
	if !vSilent!==0 (
		rem Mostra a lista de Apps
		set App[
	)
exit /b

:fazBackup
	for /l %%n in (0,1,%index%) do (
		xcopy /e /i /h /r /y "%prod%!App[%%n]!" "%prod%_backup\!App[%%n]!_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%_backup"
	)
exit /b

:listaVersoes
	echo Versoes
exit /b

:fazRollback
	echo Rollback feito
exit /b

:publica
	for /l %%n in (0,1,%index%) do (
		xcopy /e /i /h /r /y "%source%!App[%%n]!" "%prod%!App[%%n]!"
	)	
exit /b

rem Função que verifica a finalização do programa
:fim
	setlocal
	set /A vErro=%1
	if %vErro%==0 (goto :finaliza) else (goto :erro_%vErro%)
exit /b

:erro_1
	echo Arquivo de configuracao nao encontrado!
	goto :finaliza
exit /b

:erro_2
	echo Uma ou mais apps nao foram encontradas
	goto :finaliza
exit /b

:erro_3
	echo Parâmetro inválido
	goto :finaliza
eixt /b

:finaliza
	echo. -Finalizado
	echo.
exit /b

rem Lista de Parametros
:param_--help
	echo Parametros:
	echo.
	echo    -r
	echo       Faz rollback da aplicação
	echo.
	echo    -s
	echo       Faz rollback da aplicação
	echo.
	echo    --help:
	echo       Mostra essa tela