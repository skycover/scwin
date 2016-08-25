#/bin/bash

source /etc/profile
cd /usr/local/src

scwin_lib='/usr/local/lib/scwin'
src_lib='/usr/local/src'

s_user=$USERNAME
s_mail="admin@somemail.dom"
logfile="$1"

#versions of packages
scduply_version='force_full'
scdw_version="master"
scwin_version='del.arhives'

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

istall_scdw(){
	read -p "Do you want install SkyCover scdw? (y/n)" answer
	case $answer in
        [Yy])
            # little bit of magic, because you we working logging
			ask_username
			ask_password
			expect -c 'set timeout 86000
install_targz "https://github.com/skycover/scdw/tarball/$scdw_version" scdw.tar.gz
expect "Would you like to create one now? (yes/no)" {send "yes\r"}
expect "Username*" {send "'$s_user'\r"}
expect "E-mail address*" {send "'$s_mail'\r"}
expect "Password*" {send -- "'$s_password'\r"}
expect "Password*" {send -- "'$s_password'\r"}
expect eof
send_user "\n"
'
            ;;
        [Nn])
            echo skip
            return 0
            ;;
        *)
            echo "answer? (y/n)"
            ;;
    esac
}


# install_mail
[ ! -d /usr/local/src ] && mkdir /usr/local/src
cd /usr/local/src

bash ./scwin/scdwin_modules/scduply_upgrade +all +duplicity --scwin-firstinstall
install_mail

grep "ulimit -n 1024" /etc/profile > /dev/null || echo "ulimit -n 1024" >> /etc/profile
[[ ! -a ~/.scduply ]] && scduply init
[[ ! -a ~/.ssh/id_rsa.pub ]] && ssh-keygen
[[ ! -a ~/.gnupg ]] && gpg --gen-key
