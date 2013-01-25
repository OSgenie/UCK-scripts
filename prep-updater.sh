#!/bin/bash

function check_for_sudo ()
{
if [ $UID != 0 ]; then
		echo "You need root privileges"
		exit 2
fi
}

function set_servers ()
{
read -p "What is the FQDN or IP of the NFS server?" nfs_server
}

function dist-upgrade ()
{
apt-get update
apt-get dist-upgrade -y
}

function install_packages ()
{
apt-get install -y openssh-server
# install install Ubuntu Customization Kit and dependencies
apt-get install -y python-software-properties
add-apt-repository -y ppa:uck-team/uck-stable && sudo apt-get update
apt-get install -y syslinux squashfs-tools genisoimage python-software-properties xauth uck fuse-utils unionfs-fuse nfs-common #sbm
apt-get install -yf
}

function create_dirs ()
{
mkdir -p /work/live/
mkdir -p /work/install/
mkdir -p /mnt/OSgenie/
mkdir -p /var/nfs/images/
mkdir -p /iso/downloads/
mkdir -p /iso/nfs/
}

function update_fstab ()
{
fstab_entry="# nfs share for updated isos"
grep_fstab=$(grep "$fstab_entry" /etc/fstab)
if [  "$grep_fstab" != "$fstab_entry" ]; then
echo $fstab_entry >> /etc/fstab
echo "$nfs_server:/updatediso /iso/nfs nfs4 _netdev,auto 0 0" >> /etc/fstab
echo "$nfs_server:/images /var/nfs/images nfs4 _netdev,auto 0 0" >> /etc/fstab
echo "$nfs_server:/downloads /iso/downloads nfs4 _netdev,auto 0 0" >> /etc/fstab
mount -a
fi
}

function configure_root_crontab ()
{}


check_for_sudo
set_servers
dist-upgrade
install_packages
create_dirs
update_fstab