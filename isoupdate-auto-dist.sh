#!/bin/bash
# kirtley wienbroer
# kirtley@osgenie.com
folderpath=/iso/downloads
# updating server architecture
server_arch=$(dpkg --print-architecture)
server_release=$(lsb_release -rs)
# customization scripts
scriptpath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
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
array=$( ls $folderpath/ )
for option in $array; do
    iso_release='unknown'
    extension=${option##*.}
    name=$(basename $option .$extension)
    if [ $extension == "iso" ]; then
        arr=$(echo $name | tr "-" "\n")
        for x in $arr; do
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
            update_iso
        fi
    fi
done
}

function update_iso ()
{
for type in live install; do
    echo "+-------------------------------------------------------------------+"
    echo "+ UPDATING -- $distro for $type"
    echo "+-------------------------------------------------------------------+"    
    set_parameters
# for testing purposes, this prevents a previously modified isos from being modified again
#if [ ! -d $remasterdir ]; then
    set_iso_arch
    unpack_iso
    if [ -e $remasterdir/remaster-iso/casper/vmlinuz ];then
        if [ $type == 'live' ]; then
            set_isolinux_noprompt
        fi
    modify_iso
    pack_iso
    fi
#fi
done
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
fullname=$(basename "$iso")
extension=${fullname##*.}
directory=$(dirname $iso)
name=$(basename $iso .$extension)
remasterdir=/work/$type/$name
installdir=/iso/nfs/$type
isofilename="$installdir/$name-$unixtime.iso"
#	isoseed=/home/kirtley/Dropbox/Scripts/config_files/auto.seed
#	isocfg=/home/kirtley/Dropbox/Scripts/config_files/txt.cfg
}

function unpack_iso ()
{
echo "+++ UNPACKING ISO"
if [ ! -d $remasterdir ]; then
	uck-remaster-unpack-iso $iso $remasterdir
	uck-remaster-unpack-rootfs $remasterdir
	uck-remaster-unpack-initrd $remasterdir
fi
}

function set_isolinux_noprompt ()
{
echo "+++ CONFIGURING isolinux.cfg to boot live desktop"
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
echo "+++ MODIFYING ISO"
cp -rpf $scriptpath/$scripts $remasterdir/remaster-root/
echo "/$scripts/customize-iso-$type-dist"
mount -o bind $remasterdir/dev /remaster-root/dev
uck-remaster-chroot-rootfs  $remasterdir /$scripts/customize-iso-$type-dist
}

function pack_iso ()
{
echo "+++ PACKING ISO"
uck-remaster-remove-win32-files $remasterdir
rm -r $remasterdir/remaster-root/$scripts
uck-remaster-pack-initrd $remasterdir
uck-remaster-pack-rootfs $remasterdir #[-c|--clean-desktop-manifest]
#		cp -fv $isoseed $remasterdir/remaster-iso/preseed/
#		cp -fv $isocfg $remasterdir/remaster-iso/isolinux/txt.cfg
uck-remaster-pack-iso $isofilename $remasterdir --generate-md5 --arch=$isoarch --description=$name
#		uck-remaster-clean-all $remasterdir
cp -v $remasterdir/remaster-new-files/$name-$unixtime.iso.md5 /iso/nfs/$type/md5/
}

# call functions
check_for_sudo
sleep 120
update_valid_isos