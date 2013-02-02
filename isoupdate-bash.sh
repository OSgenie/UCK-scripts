#!/bin/bash
# kirtley wienbroer
# kirtley@osgenie.com
folderpath=/iso/downloads
scriptpath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
scripts=chroot
server_arch=$(dpkg --print-architecture)
server_release=$(lsb_release -rs)

function check_for_sudo ()
{
if [ $UID != 0 ]; then
		echo "You need root privileges"
		exit 2
fi
}

function create_array_of_valid_isos ()
{
array=$( ls $folderpath/ )
i=1
list=()
for option in $array; do
    iso_release='unknown'
    extension=${option##*.}
    name=$(basename $option .$extension)
    arr=$(echo $name | tr "-" "\n")
    for x in $arr; do
        if [[ $x = 'i386' || $x = 'x86' || $x = 'i686' || $x = '32bit' || $x = '32' ]]; then
            os_arch=i386
        elif [[ $x = 'amd64' || $x = 'x86_64' || $x = '64' || $x = '64bit' ]]; then
            os_arch=amd64
        fi
        if [ ${x:0:5} == $server_release ]; then
            iso_release='match'
        fi
    done
    if [ $iso_release == 'match' ] && [ $server_arch == $os_arch ]; then        
            list=(${list[@]} $option)
    fi
done
}

function user_menu ()
{
clear
echo "+-------------------------------------------------------------------+"
echo "+ OSgenie ISO Customizing Program - Bash Shell                      +"
echo "+-------------------------------------------------------------------+"
echo "Choose $server_arch iso to update: "
echo ""
for (( i=0;i<${#list[@]};i++)); do
    echo $i") "${list[$i]}
done
echo ""
read -p "Enter the number for your choice: " choice
distro=${list[$choice]}
echo "1) Customizing an ISO for Live booting"
echo "2) Customizing an ISO for Installation"
read -p "Please enter 1 or 2: " what_type
echo ""
if [ $what_type == 1 ]; then
	type=live
elif [ $what_type == 2 ]; then
	type=install
else
	exit
fi
echo "Updating $distro..."
}

function set_iso_arch ()
{
# valid options are #x86,x86_64,ia64,ppc
if [ $os_arch = "i386" ]; then
    isoarch=x86
elif [ $os_arch = "amd64" ]; then
    isoarch=x86_64
fi
}

function set_parameters ()
{
iso=$folderpath/$distro
# set parameters
unixtime=(`date +%s`)
# identify iso name
fullname=$(basename "$iso")
extension=${fullname##*.}
directory=$(dirname $iso)
name=$(basename $iso .$extension)
if [ $extension == "iso" ]; then
	# set working directories
	remasterdir=/work/$type/$name
	installdir=/iso/nfs/$type
	isofilename="$installdir/$name-$unixtime.iso"
	# customization scripts
	#isoseed=/home/kirtley/Dropbox/Scripts/config_files/auto.seed
	#isocfg=/home/kirtley/Dropbox/Scripts/config_files/txt.cfg
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
    uck-remaster-unpack-initrd $remasterdir
fi
if [ -e $remasterdir/remaster-iso/casper/vmlinuz ];then
	cp -rpvf $scriptpath/$scripts $remasterdir/remaster-root/
	mount -o bind $remasterdir/dev /remaster-root/dev
	uck-remaster-chroot-rootfs  $remasterdir /bin/bash
	uck-remaster-remove-win32-files $remasterdir
	rm -rv $remasterdir/remaster-root/$scripts
    uck-remaster-pack-initrd $remasterdir
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
cp -v $remasterdir/remaster-new-files/$name-$unixtime.iso.md5 /iso/nfs/$type/md5/
#rm -r $remasterdir
}

# call functions
check_for_sudo
create_array_of_valid_isos
user_menu
set_iso_arch
set_parameters
isoremaster
isomove

#cp -fv /home/kirtley/Dropbox/Scripts/config_files/txt.cfg.install $remasterdir/remaster-iso/isolinux/txt.cfg