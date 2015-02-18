#/bin/bash
. /etc/profile
cd /usr/local/src

scwin_lib='/usr/local/lib/scwin'

#
# Install extra packages
#

mkdir extract
cd extract


for i in ../*.tar.gz; do tar zxvf $i; done
cd GnuPGInterface-*
python setup.py install
cd ../duplicity-*
python setup.py install
cd ../Django-*
python setup.py install
cd ../skycover-scduply-*
./install.sh
cd ../skycover-scdw-*
./install.sh
cd ../..

#
# Installing scdw to Desktop
#

# do some things
cd /usr/local/src/scwin
cp ./sendmail /usr/local/bin/
cp ./mail_auth.py /usr/local/bin/
cp ./scwin_* /usr/local/bin/
ln -sf /usr/local/bin/sendmail /usr/sbin/sendmail
#
mkdir -p $scwin_lib
cp ./vss_* $scwin_lib/

#if [ -d "$USERPROFILE/Desktop" ]; then
#  cp scdw.cmd "$USERPROFILE/Desktop"
#fi

#
# Tune environment
#

echo "ulimit -n 1024" >>/etc/profile
#
# Set up cron as service
#

cron-config <<EOF
yes
ntsec
no
yes
EOF

#
# Generate ssh key
# Export public key to
#  C:\cygwin\usr\local\src\exported.pub
#  to connect SkyCover Backup service
#

ssh-keygen -b 2048 -t rsa
echo|ssh-keygen -e >exported.pub

#
# Generate GPG key
#

gpg --gen-key
