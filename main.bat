@echo off
chcp 65001 >nul
title System Hardware & Network Serial Checker
color 0A
setlocal EnableDelayedExpansion

echo ============================================
echo     SYSTEM HARDWARE & NETWORK CHECKER
echo ============================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Please run as Administrator for full hardware access!
    echo.
)

:menu
echo [1] Generate System Fingerprint
echo [2] Validate System Fingerprint
echo [3] View Hardware Serials
echo [4] Display ARP Information
echo [5] Exit
echo.
set /p choice="Select option (1-5): "

if "%choice%"=="1" goto generate
if "%choice%"=="2" goto validate
if "%choice%"=="3" goto details
if "%choice%"=="4" goto arpinfo
if "%choice%"=="5" goto end
goto menu

:generate
cls
echo [*] Collecting hardware information...
echo.

for /f "usebackq delims=" %%i in (`powershell -NoProfile "(Get-CimInstance Win32_Processor).ProcessorId"`) do set CPUID=%%i
for /f "usebackq delims=" %%i in (`powershell -NoProfile "(Get-CimInstance Win32_BaseBoard).SerialNumber"`) do set MB_SERIAL=%%i
for /f "usebackq delims=" %%i in (`powershell -NoProfile "(Get-CimInstance Win32_BIOS).SerialNumber"`) do set BIOS_SERIAL=%%i

echo CPU ID: !CPUID!
echo Motherboard Serial: !MB_SERIAL!
echo BIOS Serial: !BIOS_SERIAL!

echo.
echo [*] Generating System Fingerprint...
set "FINGERPRINT=!CPUID!!MB_SERIAL!!BIOS_SERIAL!"

set /a HASH=0
for %%d in (218 216 168 00) do (
    set /a HASH=(HASH * 31 + %%d) %% 1000000
)

set SYSTEM_ID=SYS-!HASH!
echo [+] SYSTEM FINGERPRINT: !SYSTEM_ID!

> system_info.txt (
    echo !CPUID!
    echo !MB_SERIAL!
    echo !BIOS_SERIAL!
    echo !SYSTEM_ID!
)

pause
goto menu

:validate
cls
echo [*] Validating System Fingerprint...
echo.

if not exist system_info.txt (
    echo [!] system_info.txt not found!
    pause
    goto menu
)

set line=0
for /f "tokens=*" %%a in (system_info.txt) do (
    set /a line+=1
    if !line! equ 1 set SAVED_CPU=%%a
    if !line! equ 2 set SAVED_MB=%%a
    if !line! equ 3 set SAVED_BIOS=%%a
    if !line! equ 4 set SAVED_ID=%%a
)

for /f "usebackq delims=" %%i in (`powershell -NoProfile "(Get-CimInstance Win32_Processor).ProcessorId"`) do set CUR_CPU=%%i
for /f "usebackq delims=" %%i in (`powershell -NoProfile "(Get-CimInstance Win32_BaseBoard).SerialNumber"`) do set CUR_MB=%%i
for /f "usebackq delims=" %%i in (`powershell -NoProfile "(Get-CimInstance Win32_BIOS).SerialNumber"`) do set CUR_BIOS=%%i

set CUR_FP=!CUR_CPU!!CUR_MB!!CUR_BIOS!
set /a CUR_HASH=0
for %%d in (218 216 168 00) do (
    set /a CUR_HASH=(CUR_HASH * 31 + %%d) %% 1000000
)

set CUR_ID=SYS-!CUR_HASH!

echo Saved ID:   !SAVED_ID!
echo Current ID: !CUR_ID!
echo.

if "!SAVED_ID!"=="!CUR_ID!" (
    echo [+] VALIDATION PASSED
) else (
    echo [!] VALIDATION FAILED
)

pause
goto menu

:details
cls
echo ============================================
echo           HARDWARE SERIALS
echo ============================================
echo.

echo [CPU]
powershell -NoProfile "(Get-CimInstance Win32_Processor).ProcessorId"

echo.
echo [Motherboard]
powershell -NoProfile "(Get-CimInstance Win32_BaseBoard).SerialNumber"

echo.
echo [BIOS]
powershell -NoProfile "(Get-CimInstance Win32_BIOS).SerialNumber"

echo.
echo [RAM]
powershell -NoProfile "Get-CimInstance Win32_PhysicalMemory | Select SerialNumber"

echo.
echo [Disks]
powershell -NoProfile "Get-CimInstance Win32_DiskDrive | Select SerialNumber"

echo.
echo [GPU]
powershell -NoProfile "Get-CimInstance Win32_VideoController | Select Name"

echo.
echo [MAC Addresses]
powershell -NoProfile "Get-NetAdapter | Where Status -eq 'Up' | Select MacAddress"

pause
goto menu

:arpinfo
cls
echo ============================================
echo               ARP TOOLS
echo ============================================
echo.

arp -a
echo.
echo [1] Flush ARP cache
echo [2] Delete specific ARP entry
echo [3] Add static ARP entry
echo [4] Return to menu
echo.
set /p arp_choice="Select option (1-4): "

if "%arp_choice%"=="1" (
    netsh interface ip delete arpcache
    echo [+] ARP cache flushed
    arp -a
) else if "%arp_choice%"=="2" (
    set /p del_ip="Enter IP address: "
    arp -d %del_ip%
) else if "%arp_choice%"=="3" (
    set /p add_ip="Enter IP address: "
    set /p add_mac="Enter MAC address (xx-xx-xx-xx-xx-xx): "
    arp -s %add_ip% %add_mac%
)

pause
goto menu

:license
cls
echo [*] Create License File
if not exist system_info.txt (
    echo [!] Generate fingerprint first!
    pause
    goto menu
)

set /p LICENSE_KEY="Enter license key: "
for /f "skip=3 tokens=*" %%a in (system_info.txt) do set SYSTEM_ID=%%a

:end
cls
echo Thank you for using System Hardware & Network Checker!
pause
exit
