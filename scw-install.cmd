@if (@X)==(@Y) @end /* Harmless hybrid line that begins a JScript comment
@echo off

::This block of code handles the TEE by calling the internal JScript code
@echo off
setlocal enableDelayedExpansion
:: 
if "%~1" equ "teenative" goto :tee_native
if "%~1" equ ":tee_native_tee" goto :tee_native_tee

if "%~1"=="_TEE_" (
  cscript //E:JScript //nologo "%~f0" %2 %3
  exit /b
)

:: install cygwin and scduply by Consult-MIT
:: version 201604081a
setlocal ENABLEEXTENSIONS EnableDelayedExpansion
if "%2" equ ":TeeProcess" goto TeeProcess

::
set src=%~dp0
set $s_fname=%~f0
set $s_name=%~nx0
set $loglevel=3

:: for standalone
set standalone=False

:: versions of packages
set scwin_v=master

::check admin rights
rem reg.exe query "HKU\S-1-5-19">nul 2>nul || (
rem 	call :log message "this is not admin!"
rem 	call :UACPrompt
rem 	exit /b 0
rem )

:: logfile, comment in not needed
set $logfile=%src%\scdw-install.log

:: destination
set dst=c:\cygwin
set asm=%dst%\usr\local\src

:: some variables depending on bit system
set cygsetup=setup-x86.exe
if defined ProgramFiles(x86) (
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
echo "http://cygwin.org/%cygsetup%"
call :wget_bash "http://cygwin.org/%cygsetup%" "%src%%cygsetup%"
rem call :install_cygwin 
rem call :wget_vbscript "https://github.com/skycover/scduply/tarball/%scduply_v%" "skycover-scduply.tar.gz"
rem call :create_shortcut "%%userprofile%%\desktop\CygwinTerminal.lnk" "C:\cygwin\bin\mintty.exe" " " "-i /Cygwin-Terminal.ico -"
rem call :extract_scwin || (
rem	call :log error "in module :extract_scwin"
rem	exit /b 1
rem )
rem call :postinst
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
powershell -version 1.0 -command "& {$wget = New-Object System.Net.WebClient; $wget.DownloadFile('%~1','%~2')}"
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
cscript //nologo "!vbs_script!" "%~1" "%~2"
del /f /q "!vbs_script!"
exit /b !errorlevel!
:: ==================================================================

:: ==================================================================
:wget_external
:: [url] [destination]
call :log debug "start external wget"
call :log debug "source %~1"
call :log debug "destination %~2"
call :run_program %wget% --no-check-certificate "%~1" -O "%~2"
exit /b !errorlevel!
:: ==================================================================

:: ==================================================================
:postinst
call :log message "start module :postinst"
cd /d "%src%\archives"
if not exist "skycover-scduply.tar.gz" call :run_program "%wget%" --no-check-certificate "https://github.com/skycover/scduply/tarball/%scduply_v%" -O skycover-scduply.tar.gz
if /i "%scdw_needed%" == "True" (
	call :log debug "scdw needed, download if not downloaded"
	if not exist "skycover-scdw.tar.gz" (
		call :log debug "start download scdw"
		call :run_program "%wget%" --no-check-certificate "https://github.com/skycover/scdw/tarball/%scdw_v%" -O skycover-scdw.tar.gz
	)
)
if not exist "%asm%" mkdir "%asm%"
call :log debug "start copy to /usr/"
for %%a in (*.tar.gz) do (
	xcopy "%%a" "%asm%\" /y || call :log error "error on copy %%a"
)
:: some fixes
if not exist "%asm%\scwin" mkdir "%asm%\scwin"
cd /d "%asm%\scwin"
xcopy /e /y /i "%src%\mail_module" "%asm%\scwin\mail_module\"
xcopy /e /y /i "%src%\scdwin_modules" "%asm%\scwin\scdwin_modules\"
:: end of part
:: copy scw-postinst.sh "%asm%"
call :run_program %dst%\bin\bash "%src%\scw-postinst.sh"
if /i "%scdw_needed%" == "True" (
	call :create_webscript
	call :create_shortcut "%%userprofile%%\desktop\scdw.lnk" "%asm%\scwin\scdwin_modules\scdw.bat"  "scduply web interface" 
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
set gcc=cygwin64-gcc-core
if defined ProgramFiles(x86) set gcc=mingw64-x86_64-gcc-core
set packages=python,gnupg,gcc,gcc-core,cyglsa,librsync-devel,librsync1,%gcc%,wget,vim,ncftp,openssh,cron,dos2unix,python-setuptools,expect
set server=http://cygwin.mirror.constant.com
call :log message "trying install cygwin with this packages:"
call :log %packages%
call :log with mirror %server%
if not exist "%src%\cygwin" mkdir "%src%\cygwin"
cd /d "%src%\cygwin"
call :log debug "%cd%"
if not exist "%cd%\%cygsetup%" (
	call :log debug "try dowload cygwin"
	call :run_program "%wget%" "http://cygwin.com/%cygsetup%" 
)
call :log message "start install"
call :run_program %cygsetup% -l "%src%\cygwin" -R "%dst%" -q -P "%packages%" -s "%server%" -d
call :create_shortcut "%%userprofile%%\desktop\CygwinTerminal.lnk" "C:\cygwin\bin\mintty.exe" " " "-i /Cygwin-Terminal.ico -"
call :log debug "ended installation of cygwin"
exit /b %errorlevel%
:: ==================================================================

:: ==================================================================
:: native tee method from http://stackoverflow.com/questions/11239924/windows-batch-tee-command
:tee_native
:tee_native_lock
set "teeTemp=%temp%\tee%time::=_%"
2>nul (
  9>"%teeTemp%.lock" (
    for %%F in ("%teeTemp%.test") do (
      set "yes="
      pushd "%temp%"
      copy /y nul "%%~nxF" >nul
      for /f "tokens=2 delims=(/" %%A in (
        '^<nul copy /-y nul "%%~nxF"'
      ) do if not defined yes set "yes=%%A"
      popd
    )
    for /f %%A in ("!yes!") do (
      find /n /v ""
      echo :END
      echo %%A
    ) >"%teeTemp%.tmp" | <"%teeTemp%.tmp" "%~f0" :tee_native_tee %* 7>&1 >nul
    (call )
  ) || goto :tee_native_lock
)
del "%teeTemp%.lock" "%teeTemp%.tmp" "%teeTemp%.test"
exit /b

:tee_native_tee
set "redirect=>"
if "%~3" equ "/A" set "redirect=>>"
8%redirect% %2 (call :tee_native_tee2)
set "redirect="
(echo ERROR: %~nx0 unable to open %2)>&7

:tee_native_tee2
for /l %%. in () do (
  set "ln="
  set /p "ln="
  if defined ln (
    if "!ln:~0,4!" equ ":END" exit
    set "ln=!ln:*]=!"
    (echo(!ln!)>&7
    if defined redirect (echo(!ln!)>&8
  )
)
exit /b 0
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
	echo %* >>%$logfile% 2>>%$logfile%
	%* 2>&1 | %$s_fname% _TEE_ %$logfile% 1
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

----- End of JScript comment, beginning of normal JScript  ------------------*/
var fso = new ActiveXObject("Scripting.FileSystemObject");
var mode=2;
if (WScript.Arguments.Count()==2) {mode=8;}
var out = fso.OpenTextFile(WScript.Arguments(0),mode,true);
var chr;
while( !WScript.StdIn.AtEndOfStream ) {
  chr=WScript.StdIn.Read(1);
  WScript.StdOut.Write(chr);
  out.Write(chr);
}