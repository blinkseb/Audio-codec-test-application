@ECHO OFF
rem ----Usage----
rem BuildSetup [clean|noclean] [noprompt]
rem clean to force a full rebuild
rem noclean to force a build without clean
rem noprompt to avoid all prompts
CLS
TITLE XBMC Audio Codec Test Application
rem ----PURPOSE----
rem - Create the audio codec test application
rem -------------------------------------------------------------
rem Config
rem If you get an error that Visual studio was not found, SET your path for VSNET main executable.
rem -------------------------------------------------------------
rem	CONFIG START
SET promptlevel=prompt
SET buildmode=clean
SET exitcode=0
FOR %%b in (%1, %2) DO (
	IF %%b==clean SET buildmode=clean
	IF %%b==noclean SET buildmode=noclean
	IF %%b==noprompt SET promptlevel=noprompt
)
SET buildconfig=Release

IF "%VS100COMNTOOLS%"=="" (
	set NET="%ProgramFiles%\Microsoft Visual Studio 10.0\Common7\IDE\VCExpress.exe"
) ELSE IF EXIST "%VS100COMNTOOLS%\..\IDE\VCExpress.exe" (
	set NET="%VS100COMNTOOLS%\..\IDE\VCExpress.exe"
) ELSE IF EXIST "%VS100COMNTOOLS%\..\IDE\devenv.exe" (
	set NET="%VS100COMNTOOLS%\..\IDE\devenv.exe"
)

IF NOT EXIST %NET% (
	set DIETEXT="Visual Studio .NET 2010 (Express) was not found."
	goto DIE
)

set SLN_FILE="Audio-codec-test-application.sln"
set OPTS_EXE=%SLN_FILE% /build "%buildconfig%"
set CLEAN_EXE=%SLN_FILE% /clean "%buildconfig%"
set EXE=bin\wavwriter.exe
set log=build.log

rem	CONFIG END
rem -------------------------------------------------------------
goto EXE_COMPILE

:EXE_COMPILE
	ECHO ------------------------------------------------------------
	ECHO XBMC Audio Codec Test Application
	ECHO ------------------------------------------------------------
	IF EXIST %log% del %log% /q
	IF %buildmode%==clean goto COMPILE_EXE
	IF %buildmode%==noclean goto COMPILE_NO_CLEAN_EXE

:COMPILE_EXE
	ECHO Cleaning...
	%NET% %CLEAN_EXE%
	ECHO Compiling...
	%NET% %OPTS_EXE%
	IF NOT EXIST %EXE% (
		set DIETEXT="wavwriter.exe failed to build! See build.log"
		goto DIE
	)
	ECHO Done!
	ECHO ------------------------------------------------------------
	goto END

:COMPILE_NO_CLEAN_EXE
	ECHO Compiling...
	%NET% %OPTS_EXE%
	IF NOT EXIST %EXE% (
		set DIETEXT="wavwriter.exe failed to build! See build.log"
		goto DIE
	)
	ECHO Done!
	goto END

:DIE
	ECHO ------------------------------------------------------------
	ECHO !-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-
	ECHO    ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR
	ECHO !-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-
	set DIETEXT=ERROR: %DIETEXT%
	echo %DIETEXT%
	SET exitcode=1
	ECHO ------------------------------------------------------------

:VIEWLOG_EXE
	IF NOT EXIST %log% goto END

	IF %promptlevel%==noprompt (
		goto END
	)

	set /P BUILD_ANSWER=View the build log? [y/n]
	if /I %BUILD_ANSWER% NEQ y goto END

	SET log="%CD%\" build.log

	start /D%log%
	goto END

:END
	IF %promptlevel% NEQ noprompt (
		ECHO Press any key to exit...
		pause > NUL
	)
	EXIT /B %exitcode%