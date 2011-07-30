wgets="wget --no-check-certificate"
rm master
$wgets https://github.com/skycover/scduply/tarball/master
mv master skycover-scduply-latest.tar.gz
$wgets https://github.com/skycover/scdw/tarball/master
mv master skycover-scdw-latest.tar.gz
