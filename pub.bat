@rem Welison da Silva
@echo off > NUL
chcp 65001
setlocal enableDelayedExpansion
title Publicacao + Backup (%username%)

(set \n=^
%=Do not remove this line=%
)
set /A vErro=0
set /A vSilent=1
set /A vRollback=0
set paramXCopy=/e /i /h /r /y
set paramAux=%*
set dirTeste=
set dirProd=
set dirLog=

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
		if not "!param:v=!"=="!param!" (
			set /A vSilent=0
			set paramAux=!paramAux:v=!
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

if %vSilent%==1 (
	set paramXCopy=%paramXCopy% /q
)

:inicioConfig
call :testeConfig

goto :eof

call :leConfig
call :showListaApps

set /a index=%index%-1

if %vRollback%==0 (
	call :fazBackup
	call :publica
) else (
	call :listaVersoes
	call :fazRollback
)

call :fim %vErro%
goto :eof

rem Verifica se existe arquivo de config
:testeConfig
	echo dirTeste = %dirTeste%
	echo dirProd = %dirProd%
	echo dirLog = %dirLog%
	echo -------------
	set _tempvar=
	if not exist "%diretorio%\pubsettings.ini" (
		rem if "%dirTeste%"=="" ( call :setDirSettings )
		rem if "%dirProd%"=="" ( call :setDirSettings )
		rem if "%dirLog%"=="" ( call :setDirSettings )
		if "%dirTeste%"=="" set _tempvar=1
		if "%dirProd%"=="" set _tempvar=1
		if "%dirLog%"=="" set _tempvar=1
		if "!_tempvar!"=="1" ( goto :setDirSettings )
		echo _tempvar=!_tempvar!
		
		echo teste=%dirTeste% >> %diretorio%\pubsettings.ini
		rem echo prod=%dirProd% >> %diretorio%\pubsettings.ini
		rem echo log=%dirLog% >> %diretorio%\pubsettings.ini
		goto :inicioConfig
	)
	echo -------------
	echo dirTeste = %dirTeste%
	echo dirProd = %dirProd%
	echo dirLog = %dirLog%
exit /b

:setDirSettings
	echo Entrou no setDirSettings
	if "%dirTeste%"=="" ( set /p dirTeste=Diretório do teste:)
	if "%dirProd%"=="" ( set /p dirProd=Diretório do produção: )
	if "%dirLog%"=="" ( set /p dirLog=Diretório do log: )
	goto :testeConfig
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
	echo ---^> Fazendo Backup
	for /l %%n in (0,1,%index%) do (
		echo !App[%%n]!
		xcopy %paramXCopy% "%prod%!App[%%n]!" "%prod%_backup\!App[%%n]!_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%_backup"
	)
exit /b

:listaVersoes
	pushd %source%
	dir %prod%_backup\zzz_*
	popd
	echo Versoes
exit /b

:fazRollback
	echo Rollback feito
exit /b

:publica
	echo.
	echo ---^> Publicando
	for /l %%n in (0,1,%index%) do (
		echo !App[%%n]!
		xcopy %paramXCopy% "%source%!App[%%n]!" "%prod%!App[%%n]!"
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
	echo.
	echo.
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
	echo    -v
	echo       Ativa verbosidade
	echo.
	echo    --help:
	echo       Mostra tela de ajuda