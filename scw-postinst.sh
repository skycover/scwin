#/bin/bash

source /etc/profile
cd /usr/local/src

scwin_lib='/usr/local/lib/scwin'

s_user=$USERNAME
s_mail="admin@somemail.dom"
logfile="$1"

#versions of packages
scduply_version="master"
scdw_version="master"
scwin_version="master"

pip_packages="pycrypto ecdsa lockfile paramiko pexpect"

ask_username() {
	# for scdw
	echo "You just installed Django's auth system, which means you don't have any superusers defined."
	while true;do
		read -p "Username (Leave blank to use '$s_user'):" answer
		case $answer in
			"")
				return 0
				;;
			*)
				[ ${#answer} -ge 3 -a ${#answer} -le 15 ] && {
					s_user=$answer
					return 0
				}
				;;
			esac
	done
}

ask_password() {
	# for scdw installation
	while true;do
		read -sp "Password: " pass1
		echo -e "\n"
		read -sp "Password (again): " pass2
		echo -e "\n"
		[ "${pass1}" == "${pass2}" -a ${#pass1} -ge 3 ] && {
			s_password=$pass1
			return 0
		}
		echo "Passwords don't match or too short"
	done
}

install_mail() {
    #install mail
    while true;do
    read -p "Do you want install sendmail? (y/n)" answer
    case $answer in
        [Yy])
            cp /usr/local/src/scwin/mail_module/* /usr/local/bin/
            ln -sf /usr/local/bin/sendmail /usr/sbin/sendmail
            echo "dont foget configure sendmail, config file is /usr/local/bin/mail_auth.py"
			return 0
            ;;
        [Nn])
            echo skip
            return 0
            ;;
        *)
            echo "answer? (y/n)"
            ;;
        esac
    done
}

packages () {
#packages list
# p_name=$1  ;p_=2;    3;  4         ;   5
#package name;url;file;file to start;requiered
	cat <<EOF
get-pip;https://bootstrap.pypa.io/get-pip.py;get-pip.py;get-pip.py;;
scduply;https://github.com/skycover/scduply/tarball/$scduply_version;scduply.tar.gz;install.sh;;
EOF
#scdw;https://github.com/skycover/scdw/tarball/$scdw_version;scdw.tar.gz;install.sh;;
}

cron-configuer(){
	cron-config <<EOF
yes
ntsec
no
yes
EOF

}


install_modules(){
# function to install modules
cd /usr/local/src/
packages| while read l;do
	eval $(echo $l|awk -F";" '{
		print("name="$1";")
		print("url="$2";")
		print("outputfile="$3";")
		print("startfile="$4";")
		print("required="$5";")
	}')
	wget --no-check-certificate $url -O $outputfile
	[ "$name"=="get-pip" ] && (
		python ./$outputfile && pip install $pip_packages
	) || (
		f=$(tar -tf $outputfile|head -1)
		tar -xf $outputfile
		mv $f $name
	)
	[ -d $name ] && (
		cd $name
		echo "in folder $(pwd)"
		[ -a setup.py ] && (
			echo "trying install python script"
			python ./setup.py install 2>&1
		)
		[ -a install.sh ] && (
			echo "trying install shell script"
			echo $(pwd) | grep "scdw" && (
				# little bit of magic, because you we working logging
				ask_username
				ask_password
				expect -c 'set timeout 86000
spawn ./install.sh
expect "Would you like to create one now? (yes/no)" {send "yes\r"}
expect "Username*" {send "'$s_user'\r"}
expect "E-mail address*" {send "'$s_mail'\r"}
expect "Password*" {send -- "'$s_password'\r"}
expect "Password*" {send -- "'$s_password'\r"}
expect eof
send_user "\n"
'			) || ./install.sh
		) 2>&1
		cd ..
	) || (
		echo "pass"
	)
done
}

# install_mail
[ ! -d /usr/local/src ] && mkdir /usr/local/src
cd /usr/local/src

# [ ! -d "extract" ] && mkdir extract 
#cd extract
install_modules
#cp -f /usr/local/src/scwin/scdwin_modules/scwin_* /usr/local/bin/
#[ ! -d /usr/local/lib/scwin ] && mkdir /usr/local/lib/scwin
#cp -f /usr/local/src/scwin/scdwin_modules/vss_p* /usr/local/lib/scwin/

# [ ! -z "$logfile" ] && (
	# install_modules 2>&1 |tee -a "$logfile"
# ) || install_modules


#
# Installing scdw to Desktop
#

# do some things
# cd /usr/local/src/scwin
# cp ./scwin_* /usr/local/bin/
#
# mkdir -p $scwin_lib
# cp ./vss_* $scwin_lib/

#if [ -d "$USERPROFILE/Desktop" ]; then
#  cp scdw.cmd "$USERPROFILE/Desktop"
#fi

#
# Tune environment
#

# echo "ulimit -n 1024" >>/etc/profile

#
# Set up cron as service
#


#
# Generate ssh key
# Export public key to
#  C:\cygwin\usr\local\src\exported.pub
#  to connect SkyCover Backup service
#

# ssh-keygen -b 2048 -t rsa
# echo|ssh-keygen -e >exported.pub

#
# Generate GPG key
#

# gpg --gen-key
