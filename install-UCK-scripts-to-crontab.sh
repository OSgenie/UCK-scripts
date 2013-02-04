#!/usr/bin/env bash
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function check_for_sudo ()
{
if [ $UID != 0 ]; then
		echo "You need root privileges"
		exit 2
fi
}

function install_scripts_local_bin ()
{
install $scriptdir/isoupdate-auto-list-dist.sh /usr/local/bin/update-isos
install $scriptdir/isoupdate-bash.sh /usr/local/bin/isoupdate-bash
mkdir /usr/local/bin/chroot
install $scriptdir/chroot/* /usr/local/bin/chroot/
}

function configure_crontab ()
{
echo "# m h  dom mon dow   command" | crontab -
crontab -l | { cat; echo "@reboot /usr/local/bin/update-isos  > /var/log/update-isos.log"; } | crontab -
}

check_for_sudo
install_scripts_local_bin
configure_crontab