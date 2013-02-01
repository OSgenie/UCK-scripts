#!/bin/bash
# kirtley wienbroer
# kirtley@osgenie.com
folderpath=/iso/downloads
scriptpath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
scripts=chroot
arch=$(dpkg --print-architecture)

function check_for_sudo ()
{
if [ $UID != 0 ]; then
		echo "You need root privileges"
		exit 2
fi
}

function user_menu ()
{
clear
echo "+-------------------------------------------------------------------+"
echo "+ OSgenie Automated ISO updating program                            +"
echo "+-------------------------------------------------------------------+"
echo "Choose $arch iso to update: "
echo ""
array=$( ls $folderpath/ )
i=1
for option in $array
do
    extension=${option##*.}
    name=$(basename $option .$extension)
    arr=$(echo $name | tr "-" "\n")
    for x in $arr
    do
        if [[ $x = 'i386' || $x = 'x86' || $x = 'i686' || $x = '32bit' || $x = '32' ]] && [ $arch = "i386" ]; then
            num=$((i++))
            list[$num]=$option
            echo "    $num) ${list[$num]}"
        elif [[ $x = 'amd64' || $x = 'x86_64' || $x = '64' || $x = '64bit' ]] && [ $arch = "amd64" ]; then
            num=$((i++))
            list[$num]=$option
            echo "    $num) ${list[$num]}"
        fi
    done
done
echo ""
read -p "Enter the number for your choice: " choice
distro=${list[$choice]}
echo "Updating $distro..."
}

function set_parameters ()
{
iso=$folderpath/$distro
# set parameters
if [ $arch = "i386" ]; then
isoarch=x86 #x86_64,ia64,ppc
elif [ $arch = "amd64" ]; then
isoarch=x86_64
fi
unixtime=(`date +%s`)
# identify iso name
fullname=$(basename "$iso")
extension=${fullname##*.}
directory=$(dirname $iso)
name=$(basename $iso .$extension)
	if [ $extension == "iso" ]; then
	# set working directories
	remasterdir=/work/install/$name
	installdir=/iso/nfs/install
	isofilename="$installdir/$name-$unixtime.iso"
	# customization scripts
#	isoseed=/home/kirtley/Dropbox/Scripts/config_files/auto.seed
#	isocfg=/home/kirtley/Dropbox/Scripts/config_files/txt.cfg
	else
	exit
	fi
}

function isoremaster ()
{
# run ubuntu customization kit
if [ ! -d $remasterdir ]; then
	uck-remaster-unpack-iso $iso $remasterdir
	uck-remaster-unpack-rootfs $remasterdir
fi
if [ -e $remasterdir/remaster-iso/casper/vmlinuz ];then
	cp -rpvf $scriptpath/$scripts $remasterdir/remaster-root/
	uck-remaster-chroot-rootfs  $remasterdir /bin/bash
	uck-remaster-remove-win32-files $remasterdir
	rm -rv $remasterdir/remaster-root/$scripts
	uck-remaster-pack-rootfs $remasterdir #[-c|--clean-desktop-manifest]
#		cp -v /home/kirtley/Dropbox/Scripts/config_files/auto.seed $remasterdir/remaster-iso/preseed/
#		cp -fv /home/kirtley/Dropbox/Scripts/config_files/txt.cfg.casper $remasterdir/remaster-iso/isolinux/txt.cfg
	uck-remaster-pack-iso $isofilename $remasterdir --generate-md5 --arch=$isoarch --description=$name
#		uck-remaster-clean-all $remasterdir
else
	echo "not a live cd!"
	exit
fi
}

function isomove ()
{
# copy updated iso to nfs share and clean up
#mv -v $isofilename /iso/nfs/
cp -v $remasterdir/remaster-new-files/$name-$unixtime.iso.md5 /iso/nfs/install/md5/
#rm -r $remasterdir
}

# call functions
check_for_sudo
user_menu
set_parameters
isoremaster
isomove

#cp -fv /home/kirtley/Dropbox/Scripts/config_files/txt.cfg.install $remasterdir/remaster-iso/isolinux/txt.cfg