set src=C:\Distrib\scwin
set cygsetup=setup-x86.exe
if defined ProgramFiles(x86) set cygsetup=setup-x86_64.exe
if exist %src%/%cygsetup% goto cygok
wget http://cygwin.com/%cygsetup%
if not exist %src%/%cygsetup% goto message
:cygok
set dst=c:\cygwin
set asm=%dst%\usr\local\src
set packages="python,gnupg,gcc,gcc-core,cyglsa,librsync-devel,librsync1,wget,vim,ncftp,openssh,cron"
chdir %src%
mkdir cygwin
rem Use scw-install.cmd -L to install cygwin from local directory
%cygsetup% %1 -l %src%\cygwin -R %dst% -q -P %packages%
goto qt
:message
echo You should place ditributive to %src%
echo And should run scw-install.cmd just from it.
:qt
