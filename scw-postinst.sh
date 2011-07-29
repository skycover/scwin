#/bin/bash
. /etc/profile
cd /usr/local/src
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
cd ..
echo "ulimit -n 1024" >>/etc/profile
ssh-keygen -b 2048 -t rsa
echo|ssh-keygen -e >exported.pub
