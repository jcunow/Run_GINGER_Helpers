@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "WORKDIR=%~dp0"
cd /d "%WORKDIR%"

set "MODEL=%WORKDIR%\GINGER_dataset-A.torchscript"
set "VENV=%WORKDIR%\venv\Scripts\activate.bat"
set "SPLIT=%WORKDIR%\splitfile.txt"
set "CONFIG=%WORKDIR%\ginger_config.txt"

echo ==========================
echo GINGER RUN
echo ==========================
echo.

echo TP1 = earlier timepoint image folder
echo TP2 = later timepoint image folder
echo Pairing defined in make_splitfile.py (filename-based matching)
echo Output splitfile: splitfile.txt
echo.

REM ==========================
REM LOAD CONFIG (if exists)
REM ==========================
if exist "%CONFIG%" (
    for /f "usebackq tokens=1,2 delims==" %%A in ("%CONFIG%") do (
        set "%%A=%%B"
    )
)

REM ==========================
REM MODEL SELECTION
REM ==========================
echo Model:
echo %MODEL%
echo.
set /p CONF_MODEL=Use this model? (y/n):

if /i "%CONF_MODEL%"=="y" goto model_ok
set /p MODEL=Enter full model path (.torchscript):

:model_ok
if not exist "%MODEL%" (
    echo ERROR: Model not found:
    echo %MODEL%
    pause
    exit /b
)

echo.
echo Selected model:
echo %MODEL%
echo.
pause

REM ==========================
REM INPUT FOLDERS
REM ==========================
echo.
echo ==========================
echo SELECT INPUT FOLDERS
echo (TP1 = earlier images, TP2 = later images)
echo ==========================
echo.

for /f "usebackq delims=" %%I in (`
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description='Select TP1 folder'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
`) do set TP1=%%I

for /f "usebackq delims=" %%I in (`
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description='Select TP2 folder'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
`) do set TP2=%%I

if "%TP1%"=="" (
    echo No TP1 selected.
    pause
    exit /b
)

if "%TP2%"=="" (
    echo No TP2 selected.
    pause
    exit /b
)

echo.
echo TP1: %TP1%
echo TP2: %TP2%
echo.
pause

REM ==========================
REM ENVIRONMENT
REM ==========================
call "%VENV%"

set "TP1_PATH=%TP1%"
set "TP2_PATH=%TP2%"
set "OUT_SPLIT=%SPLIT%"
set "PYTHONPATH=%WORKDIR%;%WORKDIR%\src"

REM ==========================
REM SPLITFILE
REM ==========================
echo.
echo STEP 1: Building splitfile (TP1/TP2 pairing)
python "%WORKDIR%\make_splitfile.py"

if errorlevel 1 (
    echo Splitfile generation failed.
    pause
    exit /b
)

REM ==========================
REM INFERENCE
REM ==========================
echo.
echo STEP 2: Running inference
echo Output will be written to:
echo %WORKDIR%\inference\
python "%WORKDIR%\inference.py" --model="%MODEL%" --split="%SPLIT%"

if errorlevel 1 (
    echo Inference failed.
    pause
    exit /b
)

REM ==========================
REM SAVE CONFIG (memory)
REM ==========================
(
echo TP1=%TP1%
echo TP2=%TP2%
echo MODEL=%MODEL%
) > "%CONFIG%"

echo.
echo DONE
pause