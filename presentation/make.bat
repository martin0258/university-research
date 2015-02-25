@ECHO OFF

REM Command file for building presentation

if "%1" == "" goto help

if "%1" == "help" (
	:help
	echo.Please use `make ^<target^>` where ^<target^> is one of
	echo.  oral       to make slides of oral.md
	goto end
)


if "%1" == "oral" (
	pandoc oral.md -o oral.pdf -t beamer -V theme:Madrid --template=mydefault.beamer
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished.
	goto end
)

:end
