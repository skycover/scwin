#/bin/bash

source /etc/profile
cd /usr/local/src

scwin_lib='/usr/local/lib/scwin'
src_lib='/usr/local/src'

s_user=$USERNAME
s_mail="admin@somemail.dom"
logfile="$1"

#versions of packages
scduply_version="master"
scdw_version="master"
#scwin_version="master"
duplicity_version=$(curl.exe -s http://duplicity.nongnu.org/|egrep -o "h[:/a-zA-Z0-9\.\+\-]+tar.gz"|head -1)

get_foldername() {
	# $1 file name
	if [ -e $1 -a `echo $1|grep "tar.gz$"` ];then
		tar -tf $1|head -1
		return 0
	else
		return 1
	fi
}

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

install_targz(){
	# $url $filename
	cd $src_lib
	wget --no-check-certificate "$1" -O "$2"
	folder=$(get_foldername $2)
	echo $folder
	tar -xf "$2"
	cd $folder
	echo $(pwd)
	if [[ -f install.sh ]];then
		echo "install.sh"
		./install.sh
	elif [[ -f setup.py ]];then
		echo "setup.py"
		python ./setup.py install
	fi
}

install_duplicity(){
	# function to install modules
	install_targz "$duplicity_version" duplicity.tar.gz
}

install_scduply(){
	# install scduply
	install_targz "https://github.com/skycover/scduply/tarball/$scduply_version" scduply.tar.gz
}
#echo $(pwd) | grep "scdw" && (
#				# little bit of magic, because you we working logging
#				ask_username
#				ask_password
#				expect -c 'set timeout 86000
#spawn ./install.sh
#expect "Would you like to create one now? (yes/no)" {send "yes\r"}
#expect "Username*" {send "'$s_user'\r"}
#expect "E-mail address*" {send "'$s_mail'\r"}
#expect "Password*" {send -- "'$s_password'\r"}
#expect "Password*" {send -- "'$s_password'\r"}
#expect eof
#send_user "\n"
#'			) || ./install.sh
#		) 2>&1

# install_mail
[ ! -d /usr/local/src ] && mkdir /usr/local/src
cd /usr/local/src

# [ ! -d "extract" ] && mkdir extract 
#cd extract
install_duplicity
install_scduply

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


#
# Tune environment
#

# TODO not do if exist
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

# TODO: not do if exist 
# ssh-keygen -b 2048 -t rsa
# echo|ssh-keygen -e >exported.pub

#
# Generate GPG key
#

# gpg --gen-key
