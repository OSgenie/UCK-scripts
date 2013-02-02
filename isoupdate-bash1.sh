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
fullname=$(basename "$distro")
extension=${fullname##*.}
name=$(basename $distro .$extension)
remasterdir=/work/$type/$name
installdir=/iso/nfs/$type
isofilename="$installdir/$name-$unixtime.iso"
#isoseed=/home/kirtley/Dropbox/Scripts/config_files/auto.seed
#isocfg=/home/kirtley/Dropbox/Scripts/config_files/txt.cfg
}

function unpack_iso ()
{
echo "+++ UNPACKING ISO"
if [ ! -d $remasterdir ]; then
    uck-remaster-unpack-iso $iso $remasterdir
    uck-remaster-unpack-rootfs $remasterdir
    uck-remaster-unpack-initrd $remasterdir
    cp -rpf $scriptpath/$scripts $remasterdir/remaster-root/
    mount -o bind /dev $remasterdir/remaster-root/dev
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
if [ $type == 'live' ]; then
    if [ -e $remasterdir/remaster-iso/casper/vmlinuz ]; then
        set_isolinux_noprompt
    else
        echo "Not a LiveCD"
        exit
    fi
fi
uck-remaster-chroot-rootfs  $remasterdir /bin/bash
}

function pack_iso ()
{
echo "+++ PACKING ISO"
uck-remaster-remove-win32-files $remasterdir
rm -r $remasterdir/remaster-root/$scripts
uck-remaster-pack-initrd $remasterdir
uck-remaster-pack-rootfs $remasterdir #[-c|--clean-desktop-manifest]
#cp -fv $isoseed $remasterdir/remaster-iso/preseed/
#cp -fv $isocfg $remasterdir/remaster-iso/isolinux/txt.cfg
uck-remaster-pack-iso $isofilename $remasterdir --generate-md5 --arch=$isoarch --description=$name
#uck-remaster-clean-all $remasterdir
cp -v $remasterdir/remaster-new-files/$name-$unixtime.iso.md5 /iso/nfs/$type/md5/
}

check_for_sudo
create_array_of_valid_isos
user_menu
set_iso_arch
set_parameters
unpack_iso
modify_iso
pack_iso