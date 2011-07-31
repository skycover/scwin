set src=C:\Distrib\scwin
if not exist %src%/setup.exe goto message
set dst=c:\cygwin
set asm=%dst%\usr\local\src
set packages="python,gnupg,gcc,librsync-devel,librsync1,wget,vim,ncftp,openssh,cron"
chdir %src%
mkdir cygwin
rem Use to install cygwin from the %src%/cygwin directory
rem setup.exe -L -l %src%\cygwin -R %dst% -q -P %packages%
rem Use to install cygwin from the Internet
setup.exe -l %src%\cygwin -R %dst% -q -P %packages%
mkdir %asm%
copy *.tar.gz %asm%
copy scw-postinst.sh %asm%
chdir %asm%
%dst%\bin\bash %asm%\scw-postinst.sh
chdir %src%
goto qt
:message
echo You should place ditributive to %src%
echo And should run scw-install.cmd just from it.
:qt
