@echo off
setlocal enabledelayedexpansion

echo ====== Keyboard Simulation Project ======
echo. 

where iverilog >nul 2>&1
if errorlevel 1 (
    echo ERROR: iverilog not found in PATH! 
    echo Please install Icarus Verilog and add it to PATH
    pause
    exit /b 1
)

echo ====== Compiling Keyboard Simple Simulation ======
iverilog -o keyboard_simple_sim keyboard_simple_tb.v

if errorlevel 1 (
    echo. 
    echo ERROR: Keyboard compilation failed!
    pause
    exit /b 1
)

echo Compilation successful! 
echo. 
echo ====== Running Keyboard Simple Simulation ======
vvp keyboard_simple_sim

if errorlevel 1 (
    echo.
    echo ERROR:  Keyboard simulation failed!
    pause
    exit /b 1
)

echo.
echo ====== Compiling Key to ASCII Simulation ======
iverilog -o key2ascii_sim key2ascii.v key2ascii_tb.v

if errorlevel 1 (
    echo. 
    echo ERROR: Key to ASCII compilation failed! 
    pause
    exit /b 1
)

echo Compilation successful!
echo.
echo ====== Running Key to ASCII Simulation ======
vvp key2ascii_sim

if errorlevel 1 (
    echo. 
    echo ERROR: Key to ASCII simulation failed!
    pause
    exit /b 1
)

echo.
echo ====== All Tests Complete ======
pause