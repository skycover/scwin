@echo off
:: install cygwin and scduply by Consult-MIT
:: version 201509090
setlocal ENABLEEXTENSIONS EnableDelayedExpansion
:: for log
::
set src=%~dp0
set $s_fname=%~f0
set $s_name=%~nx0
set $loglevel=3
:: for standalone
set standalone=False
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

::critical options
set wget=%src%wget.exe
if not exist "%wget%" (
    call :log error "not exist wget utility in %src%"
    exit /b 1
)

:: logfile, comment in not needed
set $logfile=%src%\scdw-install.log
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
call :install_cygwin 
call :extract_scwin || (
	call :error "in module :extract_scwin"
	exit /b 1
)
call :postinst
exit /b 0
:: ==================================================================

:: ==================================================================
:postinst
call :log message "start module :postinst"
cd "%src%\archives"
if not exist "skycover-scduply.tar.gz" "%wget%" --no-check-certificate https://github.com/skycover/scduply/tarball/%scduply_v% -O skycover-scduply.tar.gz
if not exist "skycover-scdw.tar.gz" "%wget%" --no-check-certificate https://github.com/skycover/scdw/tarball/%scdw_v% -O skycover-scdw.tar.gz
if not exist "%asm%" mkdir "%asm%"
call :log debug "start copy to /usr/"
for %%a in (*.tar.gz) do (
	xcopy "%%a" "%asm%\" /y || call :log error "error on copy %%a"
)
:: some fixes
if not exist "%asm%\scwin" mkdir "%asm%\scwin"
cd "%asm%\scwin"
xcopy /e /y /i "%src%\mail_module" "%asm%\scwin\mail_module\"
xcopy /e /y /i "%src%\scdwin_modules" "%asm%\scwin\scdwin_modules\"
:: end of part
:: copy scw-postinst.sh "%asm%"
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
set 7z=%cd%\7z.exe
call :log debug "7z is !7z!"
exit /b 0
:: ==================================================================

:: ==================================================================
:extract_scwin
call :log debug "start module :extract_scwin"
call :check_7z || (
	call :log error "in module :check_7z"
	exit /b 1
)
call :log message "start cleaning %temp% from skycover-scwin"
for /d %%a in (%temp%\skycover-scwin-*) do (
	call :log debug "tryng remove %%a in %cd%"
	rmdir /q /s %%a || call :log error "cant delete %%a"
)
call :download_scwin || (
	call :log error "in module :download_scwin, exit"
	exit /b 1
)
call :restore_scwin || (
	call :log error "in module :restore_scwin, exit"
	exit /b 1
)
for /d %%a in (%temp%\skycover-scwin-*) do (
	call :log debug "tryng remove %%a in %cd%"
	rmdir /q /s %%a || call :log error "cant delete %%a"
)
exit /b 0

:restore_scwin
:: rsync scwin
call :log debug "start module :restore_scwin"
if not exist "%src%\scwin.zip" (
	call :log error "! not exist '%src%\scwin.zip'"
	exit /b 1
)
if defined $logfile (
	"!7z!" x "%src%\scwin.zip" -o"%temp%" 2>&1 |  mtee /+ %$logfile%
) else "!7z!" x "%src%\scwin.zip" -o%temp% 2>&1
set tempscwin=
for /d %%a in (%temp%\skycover-scwin-*) do (
	set tempscwin=%%a
	goto :restore_scwin_c
)
:restore_scwin_c
if "%tempscwin%"=="" (
	call :log error "not exist scwintemp"
	exit /b 1
)
call :log debug "scwintemp = !tempscwin!"
::get excludelist
call :log message "sync %temp%\%tempscwin%"
call :run_program robocopy "%tempscwin%" "%src%\"  /XC /XO /S /R:10 || (
	call :log error "on sync src"
	exit /b 1
)
exit /b 0

:download_scwin
::download if something not exist
call :log debug "start module download_scwin"
if not exist "%src%\scwin.zip" (
	call :log message "missing %src%\scwin.zip, download"
	call :run_program "%wget%" "https://github.com/skycover/scwin/zipball/%scwin_v%" --no-check-certificate -O "%src%\scwin.zip" || (
		call :log error "on dowload scwin.zip, exit"
		exit /b 1
	)
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
call :run_program %cygsetup% %1 -l "%src%\cygwin" -R %dst% -q -P %packages% -s %server% -d
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
:run_program
call :log message "start program %*"
if defined $logfile (
	%* | mtee /d /t /+ %$logfile%
) else %*
exit /b %errorlevel%
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