set src=C:\Distrib\scwin
if not exist %src%/%cygsetup% goto message
set dst=c:\cygwin
set asm=%dst%\usr\local\src
chdir %src%
mkdir %asm%
copy *.tar.gz %asm%
copy scw-postinst.sh %asm%
copy sysstate.* %asm%
copy scdw.cmd %asm%
chdir %asm%
%dst%\bin\bash %asm%\scw-postinst.sh
chdir %src%
goto qt
:message
echo You should place ditributive to %src%
echo And should run scw-install.cmd just from it.
:qt
