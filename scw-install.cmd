@if (@X)==(@Y) @end /* Harmless hybrid line that begins a JScript comment
@echo off

if "%~1"=="_TEE_" (
  cscript //E:JScript //nologo "%~f0" %2
  exit /b
)


setlocal ENABLEEXTENSIONS EnableDelayedExpansion
:: install cygwin and scduply by Consult-MIT
:: version 201604012d
::
set src=%~dp0
set $s_fname=%~f0
set $s_name=%~nx0
set $loglevel=3

:: for standalone
set standalone=False

:: versions of packages
set scwin_v=del.arhives

::check admin rights
reg.exe query "HKU\S-1-5-19">nul 2>nul || (
 	call :log message "this is not admin!"
 	call :UACPrompt
 	exit /b 0
)

:: logfile, comment in not needed
set $logfile=%src%scdw-install.log

::for tee_native
if "%~1" equ "teenative" (
	goto :tee_native
)
:: destination
set dst=c:\cygwin
set asm=%dst%\usr\local\src

:: wget_method
set wget_method=wget_vbscript

:: some variables depending on bit system
set cygsetup=setup-x86.exe
if defined ProgramFiles(x86) (
	set cygsetup=setup-x86_64.exe
)

set tee_native=%$s_fname% _TEE_ %$logfile%
set tee_cygwin=%dst%\bin\tee.exe -a %$logfile%
set tee_internal=%src%\mtee.exe /+ %$logfile%
if exist %src%\mtee.exe (
	set tee_method=%tee_internal%
) else if exist %dst%\bin\tee.exe (
	set tee_method=%tee_cygwin%
) else (
	set tee_method=%tee_native%
)
:: проверка битности
call :winver
:: установка
call :install_all
pause
exit /b 0

:: ==================================================================
:wget
:: [source] [destination]
call :%wget_method% %1 %2
exit /b !errorlevel!
:: ==================================================================

:: ==================================================================
:: installing all things
:install_all
:: install cygwin
call :install_cygwin 
call :postinst
exit /b 0
:: ==================================================================

:: ==================================================================
:wget_bash
:: [url] [destination]
call :log debug "start bash wget"
call :log debug "source %~1"
call :log debug "destination %~2"
call :run_program %dst%\bin\bash.exe -l -c 'wget --no-check-certificate  "%~1" -O "%~2"'
exit /b !errorlevel!
:: ==================================================================


:: ==================================================================
:wget_powershell
:: [url] [destination]
call :log debug "start powershellWGET"
call :log debug "source %~1"
call :log debug "destination %~2"
call :run_program powershell -version 1.0 -command "& {$wget = New-Object System.Net.WebClient; $wget.DownloadFile('%~1','%~2')}"
exit /b !errorlevel!
:: ==================================================================

:: ==================================================================
:wget_vbscript
:: [url] [destination]
call :log debug "start VBWget"
call :log debug "source %~1"
call :log debug "destination %~2"
set vbs_script=%temp%\%random%%random%%random%.vbs
(
echo Option Explicit
echo Dim args, http, fileSystem, adoStream, url, target, status
echo.
echo Set args = Wscript.Arguments
echo Set http = CreateObject^("WinHttp.WinHttpRequest.5.1"^)
echo url = args^(0^)
echo target = args^(1^)
echo WScript.Echo "Getting '" ^& target ^& "' from '" ^& url ^& "'..."
echo.
echo http.Open "GET", url, False
echo http.Send
echo status = http.Status
echo.
echo If status ^<^> 200 Then
echo    WScript.Echo "FAILED to download: HTTP Status " ^& status
echo    WScript.Quit 1
echo End If
echo.
echo Set adoStream = CreateObject^("ADODB.Stream"^)
echo adoStream.Open
echo adoStream.Type = 1
echo adoStream.Write http.ResponseBody
echo adoStream.Position = 0
echo.
echo Set fileSystem = CreateObject^("Scripting.FileSystemObject"^)
echo If fileSystem.FileExists^(target^) Then fileSystem.DeleteFile target
echo adoStream.SaveToFile target
echo adoStream.Close
echo.
)>"!vbs_script!"
call :run_program cscript //nologo "!vbs_script!" "%~1" "%~2"
del /f /q "!vbs_script!"
exit /b !errorlevel!
:: ==================================================================

:: ==================================================================
:wget_external
:: [url] [destination]
call :log debug "start external wget"
call :log debug "source %~1"
call :log debug "destination %~2"
call :run_program "%src%wget.exe" --no-check-certificate "%~1" -O "%~2"
exit /b !errorlevel!
:: ==================================================================

:: ==================================================================
:postinst
:: 
call :log message "start module :postinst"
if not exist "%asm%" mkdir "%asm%"
:: some fixes
set path=%path%;%dst%\bin
call :wget "https://github.com/skycover/scwin/tarball/%scwin_v%" "%asm%\scwin.tar.gz"
call :log debug "extract full scwin package"
cd /d %asm%
call :run_program "%dst%\bin\tar.exe" -xvf "scwin.tar.gz"
move /y %asm%\skycover-scwin-* %asm%\scwin
xcopy /e /q /y %src%* %asm%\scwin\
call :run_program "%dst%\bin\bash.exe" "%cd%\scwin\scw-postinst.sh"
exit /b 0
:: ==================================================================

:: ==================================================================
:scwin
:: restore folder in asm
call :wget 
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
set gcc=cygwin64-gcc-core
if defined ProgramFiles(x86) set gcc=mingw64-x86_64-gcc-core
set packages=python,python-devel,gnupg,gcc,gcc-core,cyglsa,librsync-devel,librsync1,%gcc%,wget,vim,ncftp,openssh,cron,dos2unix,python-setuptools,expect,curl,libopenssl100,openssl-devel,libffi-devel,patchutils
set server=http://cygwin.mirror.constant.com
call :log message "trying install cygwin with this packages:"
call :log %packages%
call :log with mirror %server%
if not exist "%src%\cygwin" mkdir "%src%\cygwin"
cd /d "%src%\cygwin"
call :log debug "%cd%"
if not exist "%cd%\%cygsetup%" (
	call :log debug "try dowload cygwin"
	call :wget "http://cygwin.com/%cygsetup%" "%cd%\%cygsetup%" 
)
call :log debug "start install"
call :run_program %cygsetup% -l "%src%\cygwin" -R "%dst%" -q -P "%packages%" -s "%server%"

::call :create_shortcut "%%userprofile%%\desktop\CygwinTerminal.lnk" "C:\cygwin\bin\mintty.exe" " " "-i /Cygwin-Terminal.ico -"
call :log debug "ended installation of cygwin"
exit /b %errorlevel%
:: ==================================================================


:: ==================================================================
:create_shortcut
:: [destination] [target] [description] [parameters]
call :log message "start module :create_shortcut"
call :log debug %*
set cs_destination=%~1
set cs_target=%~2
set cs_description=%~3
set cs_parameters=%~4
set vbs_script=%temp%\%random%%random%%random%.vbs
echo %vbs_script%
(
   echo Set objShell = WScript.CreateObject^("WScript.Shell"^)
   echo Set lnk = objShell.CreateShortcut^("!cs_destination!"^)
   echo lnk.TargetPath = objShell.ExpandEnvironmentStrings^("!cs_target!"^)
   echo lnk.Arguments = "!cs_parameters!"
   echo lnk.Description = "!cs_description!"
   echo lnk.Save
) > %vbs_script%
cscript //nologo %vbs_script%
del /f /q "%vbs_script%"
exit /b 0
:: ==================================================================

:: ==================================================================
:create_webscript
call :log message "start module :create_webscript"
(
	echo @echo off
	echo :: start scdw + browser
	echo cd "%dst%\bin"
	echo start bash.exe -l -c scdw
	echo explorer.exe "http:\\localhost:8088"
) > %asm%\scwin\scdwin_modules\scdw.bat
exit /b 0
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
	%* 2>&1|%tee_method%
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
	call :log_printmessage
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

----- End of JScript comment, beginning of normal JScript  ------------------*/
var fso = new ActiveXObject("Scripting.FileSystemObject");
var mode=8;
var out = fso.OpenTextFile(WScript.Arguments(0),mode,true);
var chr;
while( !WScript.StdIn.AtEndOfStream ) {
  chr=WScript.StdIn.Read(1);
  WScript.StdOut.Write(chr);
  out.Write(chr);
}