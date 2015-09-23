@echo off
:: install cygwin and scduply by Consult-MIT
:: version 201509090
setlocal ENABLEEXTENSIONS EnableDelayedExpansion
:: for log
set $s_fname=%~f0
set $s_name=%~nx0
set $loglevel=3
:: for standalone
set standalone=False

::critical options
set wget=%src%wget.exe
if not exist "%wget%" (
    call :log error "not exist wget utility in %src%"
    exit /b 1
)
:: versions of packages
set scduply_v=mail_subj
set scwin_v=ver2_2
set scdw_v=master
::check admin rights
reg.exe query "HKU\S-1-5-19">nul 2>nul || (
	call :log message "this is not admin!"
	call :UACPrompt
	exit /b 0
)
::
set src=%~dp0
:: logfile, comment in not needed
set $logfile=%src%\cygwin-install.log
:: destination
set dst=c:\cygwin
set asm=%dst%\usr\local\src
:: some variables depending on bit system
set cygsetup=setup-x86.exe
set msi_7z=7z922.msi
set http_7z=http://downloads.sourceforge.net/project/sevenzip/7-Zip/9.22/7z922.msi?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fsevenzip%2Ffiles%2F7-Zip%2F9.22%2F7z922.msi
if defined ProgramFiles(x86) (
    set http_7z=http://downloads.sourceforge.net/project/sevenzip/7-Zip/9.22/7z922-x64.msi?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fsevenzip%2Ffiles%2F7-Zip%2F9.22%2F7z922-x64.msi%
    set msi_7z=7z922-x64.msi
	set cygsetup=setup-x86_64.exe
)
:: проверка битности
call :winver
:: установка
call :install_all
pause
exit /b 0

:: ==================================================================
:: installing all things
:install_all
:: install cygwin
REM call :install_cygwin 
call :extract_scwin
REM call :postinst
exit /b 0
:: ==================================================================

:: ==================================================================
:postinst
call :log message "start module :postinst"
cd "%src%\archives"
if not exist "skycover-scduply.tar.gz" wget --no-check-certificate https://github.com/skycover/scduply/tarball/%scduply_v% -O skycover-scduply.tar.gz
if not exist "skycover-scdw.tar.gz" wget --no-check-certificate https://github.com/skycover/scdw/tarball/%scdw_v% -O skycover-scdw.tar.gz
if not exist "%asm%" mkdir "%asm%"
call :log debug "start copy to /usr/"
for %%a in (*.tar.gz) do (
	xcopy "%%a" "%asm%\" /y || call :log error "error on copy %%a"
)
cd "%temp%\skycover-scwin-*"
xcopy "*.tar.gz" "%asm%\" /y || call :log error "error on copy"
:: some fixes
if not exist "%asm%\scwin" mkdir "%asm%\scwin"
cd "%asm%\scwin"
xcopy /e /y /i "%src%\mail_module" .\mail_module
xcopy /e /y /i "%src%\scdwin_modules" .\scdwin_modules
:: end of part
:: copy scw-postinst.sh "%asm%"
cd "%src%"
if defined $logfile (
	%dst%\bin\bash "%src%\scw-postinst.sh" | mtee /d /t /+ %$logfile%
) else (
	%dst%\bin\bash "%src%\scw-postinst.sh"
)
exit /b 0
:: ==================================================================

:: ==================================================================
:check_7z
call :log debug "start module :check_7z"
if not exist "%programfiles%\7-zip" (
	call :log message "7z is't installed, try install"
	cd %src%
    %wget% %http_7z% && %msi_7z% /quiet /norestart 
)
cd %programfiles%\7-zip || (
	call :log error "7z is still not installed, exit whith error!"
	exit /b 1
)
endlocal && set 7z=%cd%\7z.exe
call :log debug "7z is !7z!"
exit /b 0
:: ==================================================================

:: ==================================================================
:extract_scwin
call :log debug "start module :extract_scwin"
call :check_7z
cd "%temp%"
for /d %%a in (*-scwin-*) do (
	call :log debug "tryng remove %%a in %cd%"
	rmdir /q /s %%a || call :log error "cant delete %%a"
)
call :download_scwin
call :restore_scwin
call :log debug "start cleaning %temp%"
cd "%temp%"
for /d %%a in (%tempscwin%) do (
	call :log debug "tryng remove %%a in %cd%"
	rmdir /q /s %%a || call :log error "cant delete %%a"
)
exit /b 0

:restore_scwin
:: rsync scwin
call :log debug "start module :restore_scwin"
if not exist "%src%\scwin.zip" (
	call :log error "not exist '%src%\scwin.zip'"
	exit /b 1
)
if defined $logfile (
	"!7z!" x "%src%\scwin.zip" -o"%temp%" 2>&1 |  mtee /+ %$logfile% > %temp%\7z_scwin.log
) else "!7z!" x "%src%\scwin.zip" -o%temp% > %temp%\7z_scwin.log
:: костыль для определения имени извлеченной папки
for /f "tokens=*" %%a in ('findstr "Extracting" %temp%\7z_scwin.log') do (
	set tempscwin=%%a
	goto :restore_scwin_c
)
:restore_scwin_c
set tempscwin=!tempscwin:~12!
call :log message "!tempscwin!"
::get excludelist
cd "%tempscwin%"
call :log debug "sync %temp%\%tempscwin%"
if defined $logfile (
	robocopy "%temp%\%tempscwin%" "%src%\"  /XC /XO /S /R:10 | mtee /d /t /+ %$logfile%
) else (
	robocopy "%temp%\%tempscwin%" "%src%\"  /XC /XO /S /R:10
)
exit /b 0

:download_scwin
::download if something not exist
call :log debug "start module download_scwin"
if not exist "%src%\scwin.zip" (
	call :log message "missing %src%\scwin.zip, download"
	%wget% "https://github.com/skycover/scwin/zipball/%scwin_v%" --no-check-certificate -O "%src%\scwin.zip"
)
exit /b 0

:: ==================================================================

:: ==================================================================
:winver
:: new version of getting wininfo
for /f "tokens=2*" %%a in ('Reg QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName^|find /i "REG"') do set winver=%%b
for /f "tokens=2*" %%a in ('Reg QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CSDVersion^|find /i "REG"') do set winver=%winver% %%b
if exist "%programfiles% (x86)" ( set winver=%winver% x64) else ( set winver=%winver% x32) 
call :log message "%winver%"
exit /b 0
:: ==================================================================

:: ==================================================================
:: install cygwin online
:install_cygwin
call :log debug "start module :install_cygwin"
set packages="python,gnupg,gcc,gcc-core,cyglsa,librsync-devel,librsync1,wget,vim,ncftp,openssh,cron,dos2unix,python-setuptools,expect" 
set server="http://cygwin.mirror.constant.com" 
call :log message "trying install cygwin with this packages:"
call :log %packages%
call :log with mirror %server%
if not exist "%src%\cygwin" mkdir "%src%\cygwin"
cd "%src%\cygwin"
call :log debug "%cd%"
if not exist "%cd%\%cygsetup%" (
	call :log debug "try dowload cygwin"
	%wget% "http://cygwin.com/%cygsetup%" 
)
call :log message "start install"
if defined $logfile (
	%cygsetup% %1 -l "%src%\cygwin" -R %dst% -q -P %packages% -s %server% -d | mtee /d /t /+ %$logfile%
) else (
	%cygsetup% %1 -l "%src%\cygwin" -R %dst% -q -P %packages% -s %server% -d
)
call :log debug "ended installation of cygwin
exit /b %errorlevel%
:: ==================================================================

:: ==================================================================
:UACPrompt
:: запуск самого себя от имени администратора
mshta "vbscript:CreateObject("Shell.Application").ShellExecute("%$s_fname%", "", "%src%", "runas", 1) & Close()"
exit /b
:: ==================================================================

:: ==================================================================
:log [type] [msg]
:: definition of msg
:: $loglevel  0 nothing
::            1 message only
::            2 message + error
::            3 everything
:: type error, debug, message
::echo %~1 =====
set msg=%~2
set type=%~1
set bool=false
for %%a in (ERROR DEBUG MESSAGE) do if /i %%a==%~1 set bool=true
if "%bool%"=="false" (
	set msg=%*
	set type=
)
if /i "%~1"=="message" set type=

set msg=%date:~6,4%.%date:~3,2%.%date:~0,2% !time! %username%@%computername% %$s_name%: !type! !msg!
::echo !type! !msg!
if defined $logfile (
	call :log_printmessage >> "%$logfile%"
) else 	call :log_printmessage

exit /b 0

:log_printmessage [type] [msg]
if "%$loglevel%"=="3" (
		echo !msg!
		exit /b 0
) else if "%$loglevel%"=="2" (
	if /i "!type!"=="error" echo !msg!
	if /i "!type!"=="" echo !msg!
	exit /b 0
) else if "%$loglevel%"=="1" (
	if /i "!type!"=="" echo !msg!
) else exit /b 0
exit /b 0
:: ==================================================================