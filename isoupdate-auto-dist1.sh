#!/bin/bash
PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
HOME=/root/
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

function import_list_of_valid_isos ()
{
list=()
list=(${list[@]}
$(cat < $folderpath/updatelists/$server_release-$server_arch)
)
}

function update_valid_isos ()
{
for (( i=0;i<${#list[@]};i++)); do
    set_iso_arch
    distro=${list[$i]}
    iso=$folderpath/$distro
    unixtime=(`date +%s`)
ls -l $iso
#    update_iso
done
}

function update_iso ()
{
for type in live install; do
    echo "+-------------------------------------------------------------------+"
    echo "+ UPDATING -- $distro for $type"
    echo "+ `date +%c`"
    echo "+-------------------------------------------------------------------+"    
    set_parameters
    set_iso_arch
    unpack_iso
    if [ $type == 'install' ]; then
        modify_iso_install
    elif [ $type == 'live' ]; then
        if [ -e $remasterdir/remaster-iso/casper/vmlinuz ];then
            set_isolinux_noprompt
            modify_iso_live
        else
            echo "Not a LiveCD"
        fi
    else
        echo "+-------------------------------------------------------------------+"
        echo "+++++ ERROR -- $distro for $type"
        echo "+-------------------------------------------------------------------+"
    fi
    pack_iso
done
}

function set_iso_arch ()
{
# valid options are #x86,x86_64,ia64,ppc
if [ $os_arch == 'i386' ]; then
    isoarch=x86
elif [ $os_arch == 'amd64' ]; then
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
#isoseed=/home/kirtley/Dropbox/Scripts/config_files/auto.seed
#isocfg=/home/kirtley/Dropbox/Scripts/config_files/txt.cfg
}

function unpack_iso ()
{
echo "+++ UNPACKING ISO"
if [ ! -d $remasterdir ]; then
    uck-remaster-unpack-iso $iso $remasterdir
    uck-remaster-unpack-rootfs $remasterdir
fi
uck-remaster-unpack-initrd $remasterdir
cp -rpvf $scriptpath/$scripts $remasterdir/remaster-root/
mount -o bind /dev $remasterdir/remaster-root/dev
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

function modify_iso_live ()
{
echo "+++ MODIFYING ISO"
uck-remaster-chroot-rootfs $remasterdir /$scripts/configure-live-iso
}

function modify_iso_install ()
{
echo "+++ MODIFYING ISO"
uck-remaster-chroot-rootfs $remasterdir /$scripts/configure-install-iso
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

# call functions
check_for_sudo
echo "Waiting 120 seconds for network resources"
#sleep 120
import_list_of_valid_isos
update_valid_isos
#shutdown -h +1