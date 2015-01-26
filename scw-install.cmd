@echo off
:: install cygwin and scduply by Consult-MIT
setlocal ENABLEEXTENSIONS EnableDelayedExpansion
set $s_fname=%~f0
set $s_name=%~nx0
set $loglevel=0
::set $logfile=%public%\cygwin-install.log

::check admin rights
reg.exe query "HKU\S-1-5-19">nul 2>nul || (
	call :log message "this is not admin!"
	call :UACPrompt
	exit /b 0
)

set src=%~dp0
set dst=c:\cygwin
set asm=%dst%\usr\local\src
set cygsetup=setup-x86.exe
set msi_7z=7z922.msi
set http_7z=http://downloads.sourceforge.net/project/sevenzip/7-Zip/9.22/7z922.msi?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fsevenzip%2Ffiles%2F7-Zip%2F9.22%2F7z922.msi
if defined ProgramFiles(x86) (
    set http_7z=http://downloads.sourceforge.net/project/sevenzip/7-Zip/9.22/7z922-x64.msi?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fsevenzip%2Ffiles%2F7-Zip%2F9.22%2F7z922-x64.msi%
    set msi_7z=7z922-x64.msi
	set cygsetup=setup-x86_64.exe
)

call :winver


call :install_all

pause
exit /b 0

:: ==================================================================
:: installing all things
:install_all
cd "%src%"
if exist "%src%\%cygsetup%" ( call :cygok) else ( 
   wget.exe "http://cygwin.com/%cygsetup%" 
   call :cygok 
   if not exist scduply.zip wget "https://github.com/skycover/scwin/zipball/ver2" --no-check-certificate -O scduply.zip
	call :extract_scduply
   call :log debug "call :postinst"
   call :postinst
)
exit /b 0
:: ==================================================================

:: ==================================================================
:postinst
	chdir "%src%"
	call :log debug "%cd%"
	if not exist "skycover-scduply-latest.tar.gz" wget --no-check-certificate https://github.com/skycover/scduply/tarball/cygwin_adaptaion -O skycover-scduply-latest.tar.gz
	if not exist "skycover-scdw-latest.tar.gz" wget --no-check-certificate https://github.com/skycover/scdw/tarball/master -O skycover-scdw-latest.tar.gz
	if not exist "%asm%" mkdir "%asm%"
	copy *.tar.gz "%asm%"
	:: some fixes
	if not exist "%asm%\scwin" mkdir "%asm%\scwin"
	copy /y "%src%\pre" "%asm%\scwin\"
	copy /y "%src%\post" "%asm%\scwin\"
	copy /y "%src%\sendmail" "%asm%\scwin\"
	copy /y "%src%\mail_auth.py" "%asm%\scwin\"
	copy /y "%src%\check_vss" "%asm%\scwin\"
	:: end of part
	copy scw-postinst.sh "%asm%"
	copy scdw.cmd "%asm%"
	chdir %asm%
	call :log debug "%cd%"
	call :log debug "scw-postinst.sh"
	cd "%src%"
	%dst%\bin\bash "%src%\scw-postinst.sh" 
exit /b 0
:: ==================================================================

:: ==================================================================
:extract_scduply
call :log message "trying extract scduply.zip"
if not exist "%programfiles%\7-zip" (
	call :log debug "7z is't installed, install"
    wget %http_7z% && %msi_7z% /quiet /norestart 
)
cd %programfiles%\7-zip || (
	call :log error "7z is not installed, exit whith error!"
	exit /b 1
)
echo s | 7z e "%src%\scduply.zip" -o"%src%" 
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
:: install cygwin
:cygok
set packages="python,gnupg,gcc,gcc-core,cyglsa,librsync-devel,librsync1,wget,vim,ncftp,openssh,cron,dos2unix" 
set server="http://cygwin.mirror.constant.com" 
call :log message "trying install cygwin with this packages:"
call :log %packages%
call :log with mirror %server%
cd "%src%"
rem Use scw-install.cmd -L to install cygwin from local directory
%cygsetup% %1 -l "%src%\cygwin" -R %dst% -q -P %packages% -s %server% -d
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