@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "WORKDIR=%CD%"
set "MODEL=%WORKDIR%\GINGER_dataset-A.torchscript"
set "VENV=%WORKDIR%\venv\Scripts\activate.bat"
set "SPLIT=%WORKDIR%\splitfile.txt"

echo ==========================
echo GINGER RUN
echo ==========================
echo.

echo TP1 = earlier timepoint image folder
echo TP2 = later timepoint image folder
echo Pairing defined in make_splitfile.py (filename-based matching)
echo Output splitfile: splitfile.txt
echo.

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
REM INPUT SELECTION MESSAGE
REM ==========================
echo.
echo ==========================
echo SELECT INPUT FOLDERS
echo (TP1 = earlier images, TP2 = later images)
echo ==========================
echo.

REM --------------------------
REM TP1 / TP2 selection
REM --------------------------
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

REM --------------------------
REM Environment
REM --------------------------
call "%VENV%"

set "TP1_PATH=%TP1%"
set "TP2_PATH=%TP2%"
set "OUT_SPLIT=%SPLIT%"
set "PYTHONPATH=%WORKDIR%;%WORKDIR%\src"

REM --------------------------
REM Splitfile
REM --------------------------
echo.
echo STEP 1: Building splitfile (TP1/TP2 pairing)
python "%WORKDIR%\make_splitfile.py"

if errorlevel 1 (
    echo Splitfile generation failed.
    pause
    exit /b
)

REM --------------------------
REM Inference
REM --------------------------
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

echo.
echo DONE
pause