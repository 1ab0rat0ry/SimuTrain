@echo off
setlocal EnableDelayedExpansion

echo Starting compilation...
echo(

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "CURRENT_DIR=%SCRIPT_DIR%"
set "ERROR_COUNT=0"

:findRailWorksDirectory
if exist "%CURRENT_DIR%\RailWorks\" (
    set "RAILWORKS_DIR=%CURRENT_DIR%\RailWorks"
    goto found
)

for %%D in ("%CURRENT_DIR%") do (
    if "%%~dpD"=="%%~dD\" (
        echo Error: could not find "RailWorks" directory
        pause
        exit /b 1
    )
)

cd /d "%CURRENT_DIR%\.."
set "CURRENT_DIR=%cd%"
goto findRailWorksDirectory

:found
echo Found RailWorks directory: "%RAILWORKS_DIR%"
echo(

for /R "%SCRIPT_DIR%" %%f in (*.lua) do (
    set "FULL=%%~dpf"
    call set "REL=!FULL:%RAILWORKS_DIR%\Source\=!"
    set "OUT_DIR=%RAILWORKS_DIR%\Assets\!REL!"
    set "OUT_FILE=!OUT_DIR!%%~nf.out"

    if not exist "!OUT_DIR!" (
        mkdir "!OUT_DIR!"
    )

    echo Compiling: %%~ff
    echo Output: !OUT_FILE!
    call "%RAILWORKS_DIR%\luac.exe" -o "!OUT_FILE!" -s "%%~ff"

    if errorlevel 1 (
        set /a ERROR_COUNT+=1
    )
    echo(
)

echo(
echo Compilation finished
echo Errors: !ERROR_COUNT!
