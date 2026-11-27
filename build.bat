@echo off
setlocal DisableDelayedExpansion
if /I "%~1"=="/?" goto help
if /I "%~1"=="--help" goto help
if /I "%~1"=="-h" goto help

if not defined SCOOBY_MANAGER_ROOT set "SCOOBY_MANAGER_ROOT=%~dp0..\scooby-ps4\Apps\Scooby-Manager"
if not exist "%SCOOBY_MANAGER_ROOT%\build.bat" (
    echo Scooby Manager source was not found at "%SCOOBY_MANAGER_ROOT%". 1>&2
    echo Clone scooby-ps4 next to this repository or set SCOOBY_MANAGER_ROOT to its Apps\Scooby-Manager folder. 1>&2
    exit /b 1
)

call "%SCOOBY_MANAGER_ROOT%\build.bat" %*
exit /b %ERRORLEVEL%

:help
echo build.bat [Scooby Manager build options]
echo The default build writes the PKG to the source checkout's Apps\Scooby-Manager\out folder.
echo Use -NonInteractive to build without the version prompt.
echo Set SCOOBY_MANAGER_ROOT if the Scooby Manager sources are in a different location.
exit /b 0
