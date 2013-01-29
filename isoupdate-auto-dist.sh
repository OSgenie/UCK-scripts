#!/bin/bash
# kirtley wienbroer
# kirtley@osgenie.com

# updating server architecture
server_arch=$(dpkg --print-architecture)
server_release=$(lsb_release -rs)
# customization scripts
scriptpath=/home/kirtley/git/updater
scripts=chroot

function check_for_sudo ()
{
if [ $UID != 0 ]; then
		echo "You need root privileges"
		exit 2
fi
}

function update_valid_isos ()
{
folderpath=/iso/downloads
array=$( ls $folderpath/ )
for option in $array
do
    iso_release='unknown'
    extension=${option##*.}
    name=$(basename $option .$extension)
    arr=$(echo $name | tr "-" "\n")
    for x in $arr
    do
        if [[ $x = 'i386' || $x = 'x86' || $x = 'i686' || $x = '32bit' || $x = '32' ]]; then
            os_arch='i386'
        elif [[ $x = 'amd64' || $x = 'x86_64' || $x = '64' || $x = '64bit' ]]; then
            os_arch='amd64'
        fi
        if [ ${x:0:5} == $server_release ]; then
            iso_release='match'
        fi
    done
if [ $os_arch == $server_arch ] && [ $iso_release = 'match' ]; then
    set_iso_arch
    distro=$option
    iso=$folderpath/$distro
    unixtime=(`date +%s`)
    update_isos
fi
done
}

function update_isos ()
{
for type in live install
do
    set_parameters
    unpack_iso
    if [ $type == 'live' ]; then
        set_isolinux_noprompt
    fi
    modify_iso
    pack_iso
done
}

function set_iso_arch ()
{
#Valid options are x86,x86_64,ia64,ppc
if [ $os_arch = "i386" ]; then
isoarch=x86
elif [ $os_arch = "amd64" ]; then
isoarch=x86_64
fi
}

function set_parameters ()
{
fullname=$(basename "$iso")
extension=${fullname##*.}
directory=$(dirname $iso)
name=$(basename $iso .$extension)
if [ $extension == "iso" ]; then
    remasterdir=/work/$type/$name
    installdir=/iso/nfs/$type
    isofilename="$installdir/$name-$unixtime.iso"
    #	isoseed=/home/kirtley/Dropbox/Scripts/config_files/auto.seed
    #	isocfg=/home/kirtley/Dropbox/Scripts/config_files/txt.cfg
    else
    exit
fi
}

function unpack_iso ()
{
# run ubuntu customization kit
if [ ! -d $remasterdir ]; then
	uck-remaster-unpack-iso $iso $remasterdir
	uck-remaster-unpack-rootfs $remasterdir
fi
}

function set_isolinux_noprompt ()
{
echo "isolinux"
rm $remasterdir/remaster-iso/isolinux/isolinux.cfg
echo "default live" > $remasterdir/remaster-iso/isolinux/isolinux.cfg
echo "label live" >> $remasterdir/remaster-iso/isolinux/isolinux.cfg
echo "  say Booting an Ubuntu Live session..." >> $remasterdir/remaster-iso/isolinux/isolinux.cfg
echo "  kernel /casper/vmlinuz" >> $remasterdir/remaster-iso/isolinux/isolinux.cfg
echo "  append  file=/cdrom/preseed/ubuntu.seed boot=casper initrd=/casper/initrd.lz noprompt quiet splash --" >> $remasterdir/remaster-iso/isolinux/isolinux.cfg
chmod 444 $remasterdir/remaster-iso/isolinux/isolinux.cfg
}

function modify_iso ()
{
if [ -e $remasterdir/remaster-iso/casper/vmlinuz ];then
	cp -rpvf $scriptpath/$scripts $remasterdir/remaster-root/
	uck-remaster-chroot-rootfs  $remasterdir /$scripts/customize-iso-$type-dist
else
	echo "not a live cd!"
	exit
fi
}

function pack_iso ()
{
uck-remaster-remove-win32-files $remasterdir
rm -rv $remasterdir/remaster-root/$scripts
uck-remaster-pack-rootfs $remasterdir #[-c|--clean-desktop-manifest]
#		cp -fv $isoseed $remasterdir/remaster-iso/preseed/
#		cp -fv $isocfg $remasterdir/remaster-iso/isolinux/txt.cfg
uck-remaster-pack-iso $isofilename $remasterdir --generate-md5 --arch=$isoarch --description=$name
#		uck-remaster-clean-all $remasterdir
cp -v $remasterdir/remaster-new-files/$name-$unixtime.iso.md5 /iso/nfs/$type/md5/
}

# call functions
check_for_sudo
update_valid_isos